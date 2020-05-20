defmodule Grizzly.Connections.SyncConnection do
  @moduledoc false

  # Module for establishing a "connection" to a Z-Wave Node

  use GenServer

  require Logger

  alias Grizzly.{ZIPGateway, Connections}
  alias Grizzly.Commands.CommandRunner
  alias Grizzly.Connections.{KeepAlive, CommandList}
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

  @type opt :: {:transport, module()}

  @type send_opt :: {:timeout, non_neg_integer()} | {:retries, non_neg_integer()}

  defmodule State do
    @moduledoc false
    defstruct transport: nil,
              socket: nil,
              commands: CommandList.empty(),
              keep_alive: nil
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
          :ok | {:ok, Command.t()} | {:queued, reference(), Command.delay_seconds()}
  def send_command(node_id, command, opts \\ []) do
    name = Connections.make_name(node_id)
    GenServer.call(name, {:send_command, command, opts}, 140_000)
  end

  def close(node_id) do
    name = Connections.make_name(node_id)
    GenServer.stop(name, :normal)
  end

  def init([node_id, opts]) do
    host = ZIPGateway.host_for_node(node_id)
    port = ZIPGateway.port()
    transport = Connections.get_transport_from_opts(opts)

    case transport.open(host, port) do
      {:ok, socket} ->
        {:ok, %State{socket: socket, transport: transport, keep_alive: KeepAlive.init(25_000)}}

      {:error, :timeout} ->
        {:stop, :timeout}
    end
  end

  def handle_call({:send_command, command, command_opts}, from, state) do
    {:ok, command_runner, _, new_command_list} =
      CommandList.create(state.commands, command, from, command_opts)

    case do_send_command(command_runner, state) do
      :ok ->
        {:noreply,
         %State{
           state
           | commands: new_command_list,
             keep_alive: KeepAlive.timer_restart(state.keep_alive)
         }}
    end
  end

  def handle_info(:keep_alive_tick, state) do
    %State{keep_alive: keep_alive} = state

    new_keep_alive =
      keep_alive
      |> KeepAlive.make_command()
      |> KeepAlive.run(&do_send_command(&1, state))

    {:noreply, %State{state | keep_alive: new_keep_alive}}
  end

  # handle when there is a timeout and command runner stops
  def handle_info(
        {:grizzly, :command_timeout, command_runner_pid, grizzly_command},
        state
      ) do
    if grizzly_command.source.name == :keep_alive do
      {:noreply, state}
    else
      waiter = CommandList.get_waiter_for_runner(state.commands, command_runner_pid)
      do_timeout_reply(waiter, grizzly_command)

      {:noreply,
       %State{
         state
         | commands: CommandList.drop_command_runner(state.commands, command_runner_pid)
       }}
    end
  end

  def handle_info(data, state) do
    case state.transport.parse_response(data) do
      {:ok, zip_packet} ->
        _ = Logger.debug("Recv Z/IP Packet: #{inspect(zip_packet)}")
        new_state = handle_commands(zip_packet, state)
        {:noreply, new_state}
    end
  end

  defp handle_commands(%Command{name: :keep_alive}, state) do
    %State{state | keep_alive: KeepAlive.timer_restart(state.keep_alive)}
  end

  defp handle_commands(zip_packet, state) do
    case Command.param!(zip_packet, :flag) do
      :ack_request ->
        ## TODO clean up
        # Something we will get a UDP ping from the controller that requests
        # use to respond back, this handles that. This is mostly used
        # when there are messages in the Z/IP Gateway's mailbox to unsure
        # there is still someone waiting for the queued command.
        header_extensions = Command.param!(zip_packet, :header_extensions)
        seq_number = Command.param!(zip_packet, :seq_number)
        secure = Command.param!(zip_packet, :secure)

        {:ok, ack_response} =
          ZIPPacket.new(
            secure: secure,
            header_extensions: header_extensions,
            seq_number: seq_number,
            flag: :ack_response
          )

        binary = ZWave.to_binary(ack_response)
        state.transport.send(state.socket, binary)

        state

      _ ->
        do_handle_commands(zip_packet, state)
    end
  end

  defp do_handle_commands(zip_packet, state) do
    updated_state =
      case CommandList.response_for_zip_packet(state.commands, zip_packet) do
        {:retry, command_runner, new_comamnd_list} ->
          :ok = do_send_command(command_runner, state)
          %State{state | commands: new_comamnd_list}

        {:continue, new_comamnd_list} ->
          %State{state | commands: new_comamnd_list}

        {waiter, {:error, :nack_response, new_comamnd_list}} ->
          GenServer.reply(waiter, {:error, :nack_response})
          %State{state | commands: new_comamnd_list}

        {waiter, {:queued_complete, ref, response, new_command_list}} ->
          send(waiter, {:grizzly, :queued_command_response, ref, response})
          %State{state | commands: new_command_list}

        {waiter, {:queued_ping, ref, queued_seconds, new_comamnd_list}} ->
          send(waiter, {:grizzly, :queued_ping, ref, queued_seconds})
          %State{state | commands: new_comamnd_list}

        {waiter, {:queued, ref, queued_seconds, new_comamnd_list}} ->
          GenServer.reply(waiter, {:queued, ref, queued_seconds})
          %State{state | commands: new_comamnd_list}

        {waiter, {:complete, response, new_command_list}} ->
          GenServer.reply(waiter, response)
          %State{state | commands: new_command_list}
      end

    %State{updated_state | keep_alive: KeepAlive.timer_restart(state.keep_alive)}
  end

  defp do_send_command(command_runner, state) do
    binary = CommandRunner.encode_command(command_runner)
    state.transport.send(state.socket, binary)
  end

  defp do_timeout_reply(waiter, grizzly_command) do
    response = {:error, :timeout}

    if grizzly_command.status == :queued do
      {pid, _tag} = waiter
      send(pid, {:grizzly, :queued_command_response, grizzly_command.ref, response})
    else
      GenServer.reply(waiter, response)
    end
  end
end
