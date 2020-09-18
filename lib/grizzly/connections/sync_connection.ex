defmodule Grizzly.Connections.SyncConnection do
  @moduledoc false

  # Module for establishing a "connection" to a Z-Wave Node

  use GenServer

  require Logger

  alias Grizzly.{ZIPGateway, Connections, Options, Report}
  alias Grizzly.Commands.CommandRunner
  alias Grizzly.Connections.{KeepAlive, CommandList}
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

  @type send_opt() :: {:timeout, non_neg_integer()} | {:retries, non_neg_integer()}

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

  @spec start_link(Options.t(), ZWave.node_id(), [Grizzly.command_opt()]) ::
          GenServer.on_start()
  def start_link(grizzly_options, node_id, opts \\ []) do
    name = Connections.make_name(node_id)
    GenServer.start_link(__MODULE__, [grizzly_options, node_id, opts], name: name)
  end

  @spec send_command(ZWave.node_id() | pid(), Command.t(), [send_opt()]) ::
          Grizzly.send_command_response()
  def send_command(node_id, command, opts \\ []) do
    name = Connections.make_name(node_id)
    GenServer.call(name, {:send_command, command, node_id, opts}, 140_000)
  end

  @doc """
  Close the connection
  """
  @spec close(ZWave.node_id() | pid()) :: :ok
  def close(node_id_or_pid) do
    name = Connections.make_name(node_id_or_pid)
    # when stop this process the socket port that is owned
    # this process gets cleaned up for us.
    GenServer.stop(name, :normal)
  end

  def init([grizzly_options, node_id, _opts]) do
    host = ZIPGateway.host_for_node(node_id, grizzly_options)
    transport = grizzly_options.transport

    case transport.open(host, grizzly_options.zipgateway_port) do
      {:ok, socket} ->
        {:ok,
         %State{
           socket: socket,
           transport: transport,
           keep_alive: KeepAlive.init(node_id, 25_000)
         }}

      {:error, :timeout} ->
        {:stop, :timeout}
    end
  end

  def handle_call({:send_command, command, node_id, command_opts}, from, state) do
    {:ok, command_runner, _, new_command_list} =
      CommandList.create(state.commands, command, node_id, from, command_opts)

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
        new_state = handle_commands(zip_packet, state)
        {:noreply, new_state}
    end
  end

  defp handle_commands(%Command{name: :keep_alive}, state) do
    %State{state | keep_alive: KeepAlive.timer_restart(state.keep_alive)}
  end

  defp handle_commands(zip_packet, state) do
    _ = Logger.debug("Recv Z/IP Packet: #{inspect(zip_packet)}")

    case Command.param!(zip_packet, :flag) do
      :ack_request ->
        handle_ack_request(zip_packet, state)

      _ ->
        do_handle_commands(zip_packet, state)
    end
  end

  defp handle_ack_request(zip_packet, state) do
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

    if Command.param!(zip_packet, :command) != nil do
      do_handle_commands(zip_packet, state)
    else
      state
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

        {waiter, {%Report{} = report, new_comamnd_list}} when is_pid(waiter) ->
          send(waiter, {:grizzly, :report, report})
          %State{state | commands: new_comamnd_list}

        {waiter, {%Report{} = report, new_comamnd_list}} ->
          GenServer.reply(waiter, {:ok, report})
          %State{state | commands: new_comamnd_list}
      end

    %State{updated_state | keep_alive: KeepAlive.timer_restart(state.keep_alive)}
  end

  defp do_send_command(command_runner, state) do
    binary = CommandRunner.encode_command(command_runner)
    state.transport.send(state.socket, binary)
  end

  defp do_timeout_reply(waiter, grizzly_command) do
    if grizzly_command.status == :queued do
      {pid, _tag} = waiter

      report =
        Report.new(:complete, :timeout, grizzly_command.node_id,
          command_ref: grizzly_command.ref,
          queued: true
        )

      send(pid, {:grizzly, :report, report})
    else
      report =
        Report.new(:complete, :timeout, grizzly_command.node_id, command_ref: grizzly_command.ref)

      GenServer.reply(waiter, {:ok, report})
    end
  end
end
