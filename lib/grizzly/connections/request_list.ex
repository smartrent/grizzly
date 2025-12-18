defmodule Grizzly.Connections.RequestList do
  @moduledoc false

  # A list of running command processes and their waiter's for the
  # connections to track

  #### TODO separate out keep alive stuff ####

  alias Grizzly.Report
  alias Grizzly.Requests
  alias Grizzly.Requests.RequestRunner
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command, as: ZWaveCommand

  # this command is the process or GenServer waiting for a response
  # from the command
  @type request_waiter :: pid() | GenServer.from()

  @type request_list_item :: {pid(), request_waiter(), reference()}

  @type t :: %__MODULE__{
          requests: [request_list_item()],
          keep_alive_command: ZWaveCommand.t() | nil
        }

  # right now using a list but can probably use an erlang array for a
  # better implementation long term
  defstruct requests: [], keep_alive_command: nil

  def empty(), do: %__MODULE__{}

  def to_list(request_list), do: request_list.requests

  @doc """
  Create the command runtime and update the list of requests

  Returns `{:ok, command_runner_pid, command_reference, new_request_list}`
  """
  @spec create(t(), ZWaveCommand.t(), ZWave.node_id(), request_waiter(), keyword()) ::
          {:ok, pid(), reference(), t()}
  def create(request_list, command, node_id, waiter, command_opts \\ []) do
    case new_command(request_list, command, node_id, waiter, command_opts) do
      {:ok, command_runner, reference, new_request_list} ->
        {:ok, command_runner, reference, new_request_list}
    end
  end

  @spec response_for_zip_packet(t(), ZWaveCommand.t()) ::
          {:continue, t()}
          | {:retry, command_runner :: pid(), t()}
          | {request_waiter(), {Report.t(), t()}}
  def response_for_zip_packet(request_list, zip_packet) do
    case get_response_for_command(request_list, zip_packet) do
      {{:retry, command_runner}, request_list} ->
        {:retry, command_runner, %__MODULE__{requests: request_list}}

      {:continue, request_list} ->
        {:continue, %__MODULE__{requests: request_list}}

      {{%Report{queued: true, status: :inflight, type: :queued_ping} = report, command},
       request_list} ->
        waiter = waiter_as_pid(request_waiter(command))
        {waiter, {report, %__MODULE__{requests: request_list}}}

      {{%Report{queued: true, status: :complete} = report, command}, request_list} ->
        waiter = waiter_as_pid(request_waiter(command))
        {waiter, {report, %__MODULE__{requests: request_list}}}

      {{%Report{} = report, command}, request_list} ->
        waiter = request_waiter(command)
        {waiter, {report, %__MODULE__{requests: request_list}}}

      {nil, request_list} ->
        {:continue, %__MODULE__{requests: request_list}}

      # if requests that are queued, nacked, or complete will not have the command
      # back in the requests and will will return who to send the response to
      {{response, data, command}, new_request_list} ->
        waiter = request_waiter(command)
        {waiter, {response, data, %__MODULE__{requests: new_request_list}}}
    end
  end

  @doc """
  Get the waiter for the command runner
  """
  @spec get_waiter_for_runner(t(), command_runner_pid :: pid()) :: request_waiter()
  def get_waiter_for_runner(request_list, runner_pid) do
    case find_item_for_runner(request_list, runner_pid) do
      {^runner_pid, waiter, _ref} -> waiter
    end
  end

  @doc """
  Drop the item for the command runner
  """
  @spec drop_request_runner(t(), command_runner_pid :: pid()) :: t()
  def drop_request_runner(request_list, runner_pid) do
    new_requests =
      Enum.reject(request_list.requests, fn {test_runner_pid, _, _ref} ->
        test_runner_pid == runner_pid
      end)

    %__MODULE__{requests: new_requests}
  end

  @doc """
  This is useful to stop a command runner when you have a command
  reference
  """
  @spec stop_request_by_ref(t(), reference()) :: {:ok, t()}
  def stop_request_by_ref(request_list, request_ref) do
    case find_item_for_ref(request_list, request_ref) do
      {runner, _waiter, _ref} ->
        Requests.stop(runner)
        {:ok, drop_request_runner(request_list, runner)}
    end
  end

  @doc """
  Check to see if the command is in the command list by the command
  ref
  """
  @spec has_command_ref?(t(), reference()) :: boolean()
  def has_command_ref?(request_list, command_ref) do
    case find_item_for_ref(request_list, command_ref) do
      nil -> false
      {_, _, ^command_ref} -> true
    end
  end

  defp find_item_for_runner(request_list, runner_pid) do
    Enum.find(request_list.requests, fn {test_runner_pid, _waiter, _ref} ->
      test_runner_pid == runner_pid
    end)
  end

  defp find_item_for_ref(request_list, command_ref) do
    Enum.find(request_list.requests, fn {_, _, test_command_ref} ->
      test_command_ref == command_ref
    end)
  end

  defp get_response_for_command(request_list, zip_packet) do
    Enum.reduce(request_list.requests, {nil, []}, fn
      # if a command has already completed we don't need to requests anymore, so
      # we just put this one back into the list in for future incoming requests
      command, {{%Report{} = report, completed_command}, new_request_list} ->
        {{report, completed_command}, [command | new_request_list]}

      {command_runner, _request_waiter, _ref} = command, {_result, new_request_list} ->
        case RequestRunner.handle_zip_command(command_runner, zip_packet) do
          # if the command says to continue we put it back into the command list
          :continue ->
            {:continue, [command | new_request_list]}

          # if the command says to retry we put it back into the command list
          :retry ->
            {{:retry, command_runner}, [command | new_request_list]}

          # if the command has been queued we can keep holding onto the command
          %Report{status: :inflight, queued: true} = report ->
            {{report, command}, [command | new_request_list]}

          %Report{} = report ->
            {{report, command}, new_request_list}
        end
    end)
  end

  defp request_waiter({_command_runner, waiter, _command_ref}), do: waiter

  defp waiter_as_pid(pid) when is_pid(pid), do: pid
  defp waiter_as_pid({pid, _tag}), do: pid

  defp new_command(request_list, command, node_id, waiter, command_opts) do
    # only create a new reference if we are going to need it
    command_ref = Keyword.get_lazy(command_opts, :reference, fn -> make_ref() end)
    command_opts = Keyword.put_new(command_opts, :reference, command_ref)
    command_opts = Keyword.put_new(command_opts, :waiter, waiter)

    case Requests.start_request_runner(command, node_id, command_opts) do
      {:ok, command_runner} ->
        {:ok, command_runner, command_ref,
         put_request(request_list, command_runner, waiter, command_ref)}
    end
  end

  defp put_request(%__MODULE__{} = request_list, command_runner, waiter, reference) do
    %__MODULE__{
      request_list
      | requests: [{command_runner, waiter, reference} | request_list.requests]
    }
  end
end
