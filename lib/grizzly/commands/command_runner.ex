defmodule Grizzly.Commands.CommandRunner do
  @moduledoc false

  # TODO: document ownership and timeouts

  use GenServer

  alias Grizzly.Commands.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

  def child_spec([_command, _opts] = args) do
    # Don't restart the command if there is a failure
    # TODO: type out opts correctly!!
    %{id: __MODULE__, start: {__MODULE__, :start_link, args}, restart: :temporary}
  end

  @spec start_link(Command.t(), [Command.opt()]) :: GenServer.on_start()
  def start_link(command, opts \\ []) do
    opts = Keyword.merge([owner: self(), timeout: 5_000], opts)
    GenServer.start_link(__MODULE__, [command, opts])
  end

  @spec handle_zip_packet(pid(), ZIPPacket.t()) ::
          :continue
          | {:error, :nack_response}
          | {:queued, non_neg_integer()}
          | :retry
          | {:complete, any()}
  def handle_zip_packet(runner, zip_packet) do
    GenServer.call(runner, {:handle_zip_packet, zip_packet})
  end

  @spec encode_command(pid()) :: binary()
  def encode_command(runner) do
    GenServer.call(runner, :encode)
  end

  @spec seq_number(pid()) :: Grizzly.seq_number()
  def seq_number(runner) do
    GenServer.call(runner, :seq_number)
  end

  def stop(runner), do: GenServer.stop(runner, :normal)

  @impl true
  def init([command, opts]) do
    owner = Keyword.fetch!(opts, :owner)
    timeout = Keyword.fetch!(opts, :timeout)

    timeout_ref = start_timeout_counter(timeout)
    {:ok, Command.from_zwave_command(command, owner, timeout_ref, opts)}
  end

  @impl true
  def handle_call(:seq_number, _from, command), do: {:reply, command.seq_number, command}

  def handle_call({:handle_zip_packet, zip_packet}, _from, command) do
    case Command.handle_zip_packet(command, zip_packet) do
      {:continue, new_command} ->
        {:reply, :continue, new_command}

      {:complete, _result} = result ->
        {:stop, :normal, result, command}

      {:error, :nack_response, new_command} ->
        {:stop, :normal, {:error, :nack_response}, new_command}

      {:queued, seconds, new_command} ->
        {:stop, :normal, {:queued, seconds}, new_command}

      {:retry, new_command} ->
        {:reply, :retry, new_command}
    end
  end

  def handle_call(:encode, _from, command) do
    {:reply, Command.to_binary(command), command}
  end

  @impl true
  def handle_info(:timeout, command) do
    send(command.owner, {:grizzly, :command_timeout, self(), command.ref})
    {:stop, :normal, command}
  end

  defp start_timeout_counter(timeout), do: Process.send_after(self(), :timeout, timeout)
end
