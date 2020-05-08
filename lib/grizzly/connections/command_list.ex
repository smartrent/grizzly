defmodule Grizzly.Connections.CommandList do
  @moduledoc false

  # A list of running command processes and their waiter's for the
  # connections to track

  #### TODO separate out keep alive stuff ####

  require Logger

  alias Grizzly.Commands
  alias Grizzly.Commands.CommandRunner
  alias Grizzly.ZWave.Command, as: ZWaveCommand

  # this command is the process or GenServer waiting for a response
  # from the command
  @type command_waiter :: pid() | GenServer.from()

  @type command_list_item :: {pid(), command_waiter(), reference()}

  @type t :: %__MODULE__{
          commands: [command_list_item()],
          keep_alive_command: ZWaveCommand.t() | nil
        }

  # right now using a list but can probably use an erlang array for a
  # better implementation long term
  defstruct commands: [], keep_alive_command: nil

  def empty(), do: %__MODULE__{}

  def to_list(command_list), do: command_list.commands

  @doc """
  Create the command runtime and update the list of commands

  Returns `{:ok, command_runner_pid, command_reference, new_command_list}`
  """
  @spec create(t(), ZWaveCommand.t(), command_waiter(), keyword()) ::
          {:ok, pid(), reference(), t()}
  def create(command_list, command, waiter, command_opts \\ []) do
    case new_command(command_list, command, waiter, command_opts) do
      {:ok, command_runner, reference, new_command_list} ->
        {:ok, command_runner, reference, new_command_list}
    end
  end

  def create_keep_alive_command(command_list, keep_alive_command, command_opts \\ []) do
    case new_keep_alive_command(command_list, keep_alive_command, command_opts) do
      {:ok, _runner, _new_list} = result -> result
    end
  end

  @spec response_for_zip_packet(t(), ZWaveCommand.t()) ::
          {:continue, t()}
          | {:retry, command_runner :: pid(), t()}
          | {command_waiter(), {:error, :nack_response, t()} | {:complete, any(), t()}}
          | {command_waiter(), {:queued, reference(), non_neg_integer(), t()}}
  def response_for_zip_packet(command_list, zip_packet) do
    case get_response_for_command(command_list, zip_packet) do
      {:retry, command_runner, command_list} ->
        {:retry, command_runner, %__MODULE__{commands: command_list}}

      {:continue, command_list} ->
        {:continue, %__MODULE__{commands: command_list}}

      {{:queued, ref, seconds, command}, command_list} ->
        waiter = command_waiter(command)
        {waiter, {:queued, ref, seconds, %__MODULE__{commands: command_list}}}

      {nil, command_list} ->
        {:continue, %__MODULE__{commands: command_list}}

      # if commands that are queued, nacked, or complete will not have the command
      # back in the commands and will will return who to send the response to
      {{response, data, command}, new_command_list} ->
        waiter = command_waiter(command)
        {waiter, {response, data, %__MODULE__{commands: new_command_list}}}
    end
  end

  @doc """
  Get the waiter for the command runner
  """
  @spec get_waiter_for_runner(t(), command_runner_pid :: pid()) :: command_waiter()
  def get_waiter_for_runner(command_list, runner_pid) do
    case find_item_for_runner(command_list, runner_pid) do
      {^runner_pid, waiter, _ref} -> waiter
    end
  end

  @doc """
  Drop the item for the command runner
  """
  @spec drop_command_runner(t(), command_runner_pid :: pid()) :: t()
  def drop_command_runner(command_list, runner_pid) do
    new_commands =
      Enum.reject(command_list.commands, fn {test_runner_pid, _, _ref} ->
        test_runner_pid == runner_pid
      end)

    %__MODULE__{commands: new_commands}
  end

  @doc """
  This is useful to stop a command runner when you have a command
  reference
  """
  @spec stop_command_by_ref(t(), reference()) :: {:ok, t()}
  def stop_command_by_ref(command_list, command_ref) do
    case find_item_for_ref(command_list, command_ref) do
      {runner, _waiter, _ref} ->
        Commands.stop(runner)
        {:ok, drop_command_runner(command_list, runner)}
    end
  end

  @doc """
  Check to see if the command is in the command list by the command
  ref
  """
  @spec has_command_ref?(t(), reference()) :: boolean()
  def has_command_ref?(command_list, command_ref) do
    case find_item_for_ref(command_list, command_ref) do
      nil -> false
      {_, _, ^command_ref} -> true
    end
  end

  defp find_item_for_runner(command_list, runner_pid) do
    Enum.find(command_list.commands, fn {test_runner_pid, _waiter, _ref} ->
      test_runner_pid == runner_pid
    end)
  end

  defp find_item_for_ref(command_list, command_ref) do
    Enum.find(command_list.commands, fn {_, _, test_command_ref} ->
      test_command_ref == command_ref
    end)
  end

  defp get_response_for_command(command_list, zip_packet) do
    Enum.reduce(command_list.commands, {nil, []}, fn {command_runner, _command_waiter, _ref} =
                                                       command,
                                                     {_result, new_command_list} ->
      case CommandRunner.handle_zip_command(command_runner, zip_packet) do
        # if the command says to continue we put it back into the command list
        :continue ->
          {:continue, [command | new_command_list]}

        # if the command says it has a nack_response, we remove it from the command list
        {:error, :nack_response} ->
          {{:error, :nack_response, command}, new_command_list}

        # if the command says it has been queued, we remove it from the command list
        {:queued, reference, seconds} ->
          {{:queued, reference, seconds, command}, [command | new_command_list]}

        # if the command says to retry we put it back into the command list
        :retry ->
          {:retry, command_runner, [command | new_command_list]}

        # if the command says it has a nack_response, we remove it from the command list
        {:complete, response} ->
          {{:complete, response, command}, new_command_list}
      end
    end)
  end

  defp command_waiter({_command_runner, waiter, _command_ref}), do: waiter

  defp new_command(command_list, command, waiter, command_opts) do
    # only create a new reference if we are going to need it
    command_ref = Keyword.get_lazy(command_opts, :reference, fn -> make_ref() end)
    command_opts = Keyword.put_new(command_opts, :reference, command_ref)

    case Commands.create_command(command, command_opts) do
      {:ok, command_runner} ->
        {:ok, command_runner, command_ref,
         put_command(command_list, command_runner, waiter, command_ref)}
    end
  end

  defp new_keep_alive_command(command_list, command, command_opts) do
    case Commands.create_command(command, command_opts) do
      {:ok, command_runner} ->
        {:ok, command_runner, put_keep_alive(command_list, command_runner)}
    end
  end

  defp put_command(command_list, command, waiter, reference) do
    %__MODULE__{command_list | commands: [{command, waiter, reference} | command_list.commands]}
  end

  defp put_keep_alive(command_list, keep_alive_runner) do
    %__MODULE__{command_list | keep_alive_command: keep_alive_runner}
  end
end
