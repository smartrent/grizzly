defmodule Grizzly.Connections.AsyncConnection do
  @moduledoc false

  # A connection type that is useful for doing long running operations that are
  # allowed to be canceled, or if the operation may need to request more
  # information from a user.

  # don't use this connection type unless it is for a special reason. Normally,
  # you will want to wrap this connection in a GenServer as normally there is
  # some long running state tied to needing one of these connection types.

  use GenServer

  alias Grizzly.Connections
  alias Grizzly.Commands.CommandRunner
  alias Grizzly.Connections.{KeepAliveTimer, CommandList}
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.{ZIPKeepAlive, ZIPPacket}

  defmodule State do
    @moduledoc false
    defstruct transport: nil,
              socket: nil,
              commands: CommandList.empty(),
              keep_alive_timer: nil,
              owner: nil
  end

  def child_spec(node_id, opts \\ []) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [node_id, opts]}, restart: :transient}
  end

  def start_link(node_id, opts \\ []) do
    name = Connections.make_name({:async, node_id})
    GenServer.start_link(__MODULE__, [node_id, [{:owner, self()} | opts]], name: name)
  end

  @spec send_command(Grizzly.node_id(), Command.t(), keyword()) :: {:ok, reference()}
  def send_command(node_id, command, opts \\ []) do
    name = Connections.make_name({:async, node_id})
    GenServer.call(name, {:send_command, command, opts}, 140_000)
  end

  @spec stop_command(Grizzly.node_id(), reference()) :: :ok
  def stop_command(node_id, command_ref) do
    name = Connections.make_name({:async, node_id})
    GenServer.call(name, {:stop_command, command_ref})
  end

  @spec command_alive?(Grizzly.node_id(), reference()) :: boolean()
  def command_alive?(node_id, command_ref) do
    name = Connections.make_name({:async, node_id})
    GenServer.call(name, {:command_alive?, command_ref})
  end

  def stop(node_id) do
    # TODO close socket
    name = Connections.make_name({:async, node_id})
    GenServer.stop(name, :normal)
  end

  def init([node_id, opts]) do
    {host, port} = Connections.build_host_port_from_node_id(node_id)
    transport = Connections.get_transport_from_opts(opts)

    case transport.open(host, port) do
      {:ok, socket} ->
        keep_alive_timer = KeepAliveTimer.create(self())

        {:ok,
         %State{
           socket: socket,
           transport: transport,
           keep_alive_timer: keep_alive_timer,
           owner: Keyword.fetch!(opts, :owner)
         }}

      {:error, :timeout} ->
        {:stop, :timeout}
    end
  end

  def handle_call({:send_command, command, send_opts}, {waiter, _ref}, state) do
    {:ok, command_runner, command_ref, new_command_list} =
      CommandList.create(state.commands, command, waiter, send_opts)

    case do_send_command(command_runner, state) do
      :ok ->
        {:reply, {:ok, command_ref},
         %State{
           state
           | commands: new_command_list,
             keep_alive_timer: KeepAliveTimer.restart(state.keep_alive_timer)
         }}
    end
  end

  def handle_call({:stop_command, command_ref}, _from, state) do
    {:ok, new_commands} = CommandList.stop_command_by_ref(state.commands, command_ref)
    {:reply, :ok, %State{state | commands: new_commands}}
  end

  def handle_call({:command_alive?, command_ref}, _from, state) do
    {:reply, CommandList.has_command_ref?(state.commands, command_ref), state}
  end

  def handle_info(:keep_alive_tick, state) do
    {:ok, keep_alive_command} = ZIPKeepAlive.new()

    {:ok, command_runner, _, new_command_list} =
      CommandList.create(state.commands, keep_alive_command, self())

    case do_send_command(command_runner, state) do
      :ok ->
        {:noreply,
         %State{
           state
           | commands: new_command_list,
             keep_alive_timer: KeepAliveTimer.restart(state.keep_alive_timer)
         }}
    end
  end

  # handle when there is a timeout and command runner stops
  def handle_info({:grizzly, :command_timeout, command_runner_pid, command_ref}, state) do
    waiter = CommandList.get_waiter_for_runner(state.commands, command_runner_pid)
    send(waiter, {:grizzly, :send_command, {:error, :timeout, command_ref}})

    {:noreply,
     %State{
       state
       | commands: CommandList.drop_command_runner(state.commands, command_runner_pid)
     }}
  end

  def handle_info(data, state) do
    case state.transport.parse_response(data) do
      {:ok, zip_packet} ->
        updated_state = handle_commands(zip_packet, state)

        {:noreply,
         %State{updated_state | keep_alive_timer: KeepAliveTimer.restart(state.keep_alive_timer)}}
    end
  end

  defp handle_commands(zip_packet, state) do
    self = self()

    case CommandList.response_for_zip_packet(state.commands, zip_packet) do
      {:retry, command_runner, new_comamnd_list} ->
        :ok = do_send_command(command_runner, state)
        %State{state | commands: new_comamnd_list}

      {:continue, new_comamnd_list} ->
        if !ZIPPacket.ack_response?(zip_packet) do
          # Since we are doing async communications we need to handle when the
          # connection gets an unhandled command from the Z-Wave
          send(state.owner, {:grizzly, :unhandled_command, zip_packet.command})
        end

        %State{state | commands: new_comamnd_list}

      # this if for the keep alive as this process only
      # waits for that command
      {^self, {_, _, new_comamnd_list}} ->
        %State{state | commands: new_comamnd_list}

      {waiter, {:error, :nack_response, new_comamnd_list}} ->
        send(waiter, {:grizzly, :send_command, {:error, :nack_response}})
        %State{state | commands: new_comamnd_list}

      {waiter, {:queued, queued_seconds, new_comamnd_list}} ->
        send(waiter, {:grizzly, :send_command, {:queued, queued_seconds}})
        %State{state | commands: new_comamnd_list}

      {waiter, {:complete, response, new_comamnd_list}} ->
        send(waiter, {:grizzly, :send_command, response})
        %State{state | commands: new_comamnd_list}
    end
  end

  defp do_send_command(command_runner, state) do
    binary = CommandRunner.encode_command(command_runner)

    state.transport.send(state.socket, binary)
  end

  def send_response(from, zip_packet, command_ref, response) do
    if ZIPPacket.ack_response?(zip_packet) do
      send(from, {:grizzly, :ack_response, command_ref, response})
    else
      send(from, {:grizzly, zip_packet.command.name, command_ref, response})
    end
  end
end
