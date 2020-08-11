defmodule Grizzly.Commands.CommandRunner do
  @moduledoc false

  # TODO: document ownership and timeouts

  use GenServer

  alias Grizzly.Report
  alias Grizzly.Commands.Command
  alias Grizzly.ZWave.Command, as: ZWaveCommand

  def child_spec([_command, _node_id, _opts] = args) do
    # Don't restart the command if there is a failure
    # TODO: type out opts correctly!!
    %{id: __MODULE__, start: {__MODULE__, :start_link, args}, restart: :temporary}
  end

  @spec start_link(Command.t(), [Grizzly.command_opt()]) :: GenServer.on_start()
  def start_link(command, node_id, opts \\ []) do
    opts = Keyword.merge([owner: self(), timeout: 5_000], opts)
    GenServer.start_link(__MODULE__, [command, node_id, opts])
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

  def stop(runner), do: GenServer.stop(runner, :normal)

  @impl true
  def init([command, node_id, opts]) do
    owner = Keyword.fetch!(opts, :owner)
    timeout = Keyword.fetch!(opts, :timeout)
    timeout_ref = start_timeout_counter(timeout)
    opts = Keyword.merge(opts, timeout_ref: timeout_ref)

    {:ok, Command.from_zwave_command(command, node_id, owner, opts)}
  end

  @impl true
  def handle_call(:seq_number, _from, command), do: {:reply, command.seq_number, command}

  def handle_call({:handle_zip_command, zip_packet}, _from, command) do
    case Command.handle_zip_command(command, zip_packet) do
      {%Report{status: :inflight} = report, new_command} ->
        new_command = update_timeout(new_command, report.queued_delay)
        {:reply, report, new_command}

      {%Report{status: :complete} = report, new_command} ->
        {:stop, :normal, report, new_command}

      {:continue, new_command} ->
        {:reply, :continue, new_command}

      {:error, :nack_response, new_command} ->
        {:stop, :normal, {:error, :nack_response}, new_command}

      {:retry, new_command} ->
        {:reply, :retry, new_command}
    end
  end

  def handle_call(:reference, _from, command) do
    {:reply, command.ref, command}
  end

  def handle_call(:encode, _from, command) do
    {:reply, Command.to_binary(command), command}
  end

  @impl true
  def handle_info(:timeout, command) do
    send(command.owner, {:grizzly, :command_timeout, self(), command})
    {:stop, :normal, command}
  end

  defp update_timeout(command, time_in_seconds) do
    _ = Process.cancel_timer(command.timeout_ref)
    new_timeout_ref = start_timeout_counter(time_in_seconds * 1000 + 500)
    %Command{command | timeout_ref: new_timeout_ref}
  end

  defp start_timeout_counter(timeout), do: Process.send_after(self(), :timeout, timeout)
end
