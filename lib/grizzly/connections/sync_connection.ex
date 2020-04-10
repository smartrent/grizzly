defmodule Grizzly.Connections.SyncConnection do
  @moduledoc false

  # Module for establishing a "connection" to a Z-Wave Node

  use GenServer

  require Logger

  alias Grizzly.{ZIPGateway, Connections}
  alias Grizzly.Commands.CommandRunner
  alias Grizzly.Connections.{KeepAliveTimer, CommandList}
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPKeepAlive

  @type opt :: {:transport, module()}

  @type send_opt :: {:timeout, non_neg_integer()} | {:retries, non_neg_integer()}

  defmodule State do
    @moduledoc false
    defstruct transport: nil, socket: nil, commands: CommandList.empty(), keep_alive_timer: nil
  end

  def child_spec(node_id, opts \\ []) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [node_id, opts]}, restart: :transient}
  end

  @spec start_link(Grizzly.node_id(), [opt]) :: GenServer.on_start()
  def start_link(node_id, opts \\ []) do
    name = Connections.make_name(node_id)
    GenServer.start_link(__MODULE__, [node_id, opts], name: name)
  end

  @spec send_command(Grizzly.node_id(), Command.t(), [send_opt()]) ::
          :ok | {:ok, Command.t()} | {:queued, Command.delay_seconds()}
  def send_command(node_id, command, opts \\ []) do
    name = Connections.make_name(node_id)
    GenServer.call(name, {:send_command, command, opts}, 140_000)
  end

  def close(node_id) do
    name = Connections.make_name(node_id)
    GenServer.stop(name, :normal)
  end

  def init([node_id, opts]) do
    require Logger

    host = ZIPGateway.host_for_node(node_id)
    port = ZIPGateway.port()
    transport = Connections.get_transport_from_opts(opts)

    case transport.open(host, port) do
      {:ok, socket} ->
        keep_alive_timer = KeepAliveTimer.create(self())
        {:ok, %State{socket: socket, transport: transport, keep_alive_timer: keep_alive_timer}}

      {:error, :timeout} ->
        {:stop, :timeout}
    end
  end

  def handle_call({:send_command, command, send_opts}, from, state) do
    {:ok, command_runner, _, new_command_list} =
      CommandList.create(state.commands, command, from, send_opts)

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

  def handle_info(:keep_alive_tick, state) do
    {:ok, zip_keep_alive} = ZIPKeepAlive.new()

    {:ok, command_runner, _, new_command_list} =
      CommandList.create(state.commands, zip_keep_alive, self())

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
  def handle_info({:grizzly, :command_timeout, command_runner_pid, _ref}, state) do
    waiter = CommandList.get_waiter_for_runner(state.commands, command_runner_pid)
    GenServer.reply(waiter, {:error, :timeout})

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
        %State{state | commands: new_comamnd_list}

      # this if for the keep alive as this process only
      # waits for that command
      {^self, {_, _, new_comamnd_list}} ->
        %State{state | commands: new_comamnd_list}

      {waiter, {:error, :nack_response, new_comamnd_list}} ->
        GenServer.reply(waiter, {:error, :nack_response})
        %State{state | commands: new_comamnd_list}

      {waiter, {:queued, queued_seconds, new_comamnd_list}} ->
        GenServer.reply(waiter, {:queued, queued_seconds})
        %State{state | commands: new_comamnd_list}

      {waiter, {:complete, response, new_comamnd_list}} ->
        GenServer.reply(waiter, response)
        %State{state | commands: new_comamnd_list}
    end
  end

  defp do_send_command(command_runner, state) do
    binary = CommandRunner.encode_command(command_runner)

    state.transport.send(state.socket, binary)
  end
end
