defmodule Grizzly.Requests.RequestRunner do
  @moduledoc false

  # TODO: document ownership and timeouts

  use GenServer

  alias Grizzly.Report
  alias Grizzly.Requests.Request
  alias Grizzly.ZWave.Command, as: ZWaveCommand

  def child_spec([_command, _node_id, _opts] = args) do
    # Don't restart the command if there is a failure
    # TODO: type out opts correctly!!
    %{id: __MODULE__, start: {__MODULE__, :start_link, args}, restart: :temporary}
  end

  @spec start_link(Request.t(), [Grizzly.command_opt()]) :: GenServer.on_start()
  def start_link(request, node_id, opts \\ []) do
    opts = Keyword.merge([owner: self(), timeout: 15_000], opts)
    GenServer.start_link(__MODULE__, [request, node_id, opts])
  end

  @spec handle_zip_command(pid(), ZWaveCommand.t()) ::
          Report.t()
          | :continue
          | {:error, :nack_response}
          | :retry
  def handle_zip_command(runner, zip_packet) do
    GenServer.call(runner, {:handle_zip_command, zip_packet})
  end

  @spec encode_command(pid()) :: binary()
  def encode_command(runner) do
    GenServer.call(runner, :encode)
  end

  @spec seq_number(pid()) :: Grizzly.seq_number()
  def seq_number(runner) do
    GenServer.call(runner, :seq_number)
  end

  @spec reference(pid()) :: reference()
  def reference(runner) do
    GenServer.call(runner, :reference)
  end

  def stop(runner) do
    GenServer.stop(runner, :normal)
  catch
    :exit, {:noproc, _} -> :ok
  end

  @impl GenServer
  def init([command, node_id, opts]) do
    owner = Keyword.fetch!(opts, :owner)
    timeout = Keyword.fetch!(opts, :timeout)
    timeout_ref = start_timeout_counter(timeout)
    opts = Keyword.merge(opts, timeout_ref: timeout_ref)

    {:ok, Request.from_zwave_command(command, node_id, owner, opts)}
  end

  @impl GenServer
  def handle_call(:seq_number, _from, request), do: {:reply, request.seq_number, request}

  def handle_call({:handle_zip_command, zip_packet}, _from, request) do
    case Request.handle_zip_command(request, zip_packet) do
      {%Report{status: :inflight} = report, new_request} ->
        new_request = update_timeout(new_request, report.queued_delay)
        {:reply, report, new_request}

      {%Report{status: :complete} = report, new_request} ->
        {:stop, :normal, report, new_request}

      {:continue, new_request} ->
        {:reply, :continue, new_request}

      {:retry, new_request} ->
        {:reply, :retry, new_request}
    end
  end

  def handle_call(:reference, _from, request) do
    {:reply, request.ref, request}
  end

  def handle_call(:encode, _from, request) do
    {:reply, Request.to_binary(request), request}
  end

  @impl GenServer
  def handle_info(:timeout, request) do
    # TODO: :command_timeout -> :request_timeout?
    send(request.owner, {:grizzly, :command_timeout, self(), request})
    {:stop, :normal, request}
  end

  defp update_timeout(request, time_in_seconds) do
    _ = Process.cancel_timer(request.timeout_ref)
    new_timeout_ref = start_timeout_counter(time_in_seconds * 1000 + 500)
    %Request{request | timeout_ref: new_timeout_ref}
  end

  defp start_timeout_counter(timeout), do: Process.send_after(self(), :timeout, timeout)
end
