defmodule Grizzly.Connections.AsyncConnection do
  @moduledoc false

  # A connection type that is useful for doing long running operations that are
  # allowed to be canceled, or if the operation may need to request more
  # information from a user.

  # don't use this connection type unless it is for a special reason. Normally,
  # you will want to wrap this connection in a GenServer as normally there is
  # some long running state tied to needing one of these connection types.

  use GenServer

  alias Grizzly.Commands.CommandRunner
  alias Grizzly.Connections.{CommandList, KeepAlive}
  alias Grizzly.{Connection, Connections, Options, Report, Transport, ZIPGateway, ZWave}
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

  import Grizzly.NodeId, only: [is_zwave_node_id: 1]

  require Logger

  defmodule State do
    @moduledoc false
    defstruct transport: nil,
              socket: nil,
              commands: CommandList.empty(),
              owner: nil,
              monitor_ref: nil,
              keep_alive: nil,
              node_id: nil
  end

  def child_spec(node_id, opts \\ []) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [node_id, opts]}, restart: :transient}
  end

  @spec start_link(Options.t(), ZWave.node_id(), [Connection.opt()]) :: GenServer.on_start()
  def start_link(grizzly_options, node_id, opts \\ []) do
    opts = Keyword.put_new(opts, :owner, self())
    unnamed = Keyword.get(opts, :unnamed, false)

    start_opts =
      if unnamed do
        []
      else
        [name: Connections.make_name({:async, node_id})]
      end

    GenServer.start_link(__MODULE__, [grizzly_options, node_id, opts], start_opts)
  end

  @spec send_command(GenServer.name() | Grizzly.node_id(), Command.t(), keyword()) ::
          {:ok, reference()}
  def send_command(node_id_or_conn, command, opts \\ [])

  def send_command(node_id, command, opts) when is_zwave_node_id(node_id) do
    name = make_name(node_id)
    send_command(name, command, opts)
  end

  def send_command(connection, command, opts) do
    GenServer.call(connection, {:send_command, command, opts}, 140_000)
  end

  @spec stop_command(Grizzly.node_id() | pid(), reference()) :: :ok
  def stop_command(node_id, command_ref) do
    name = make_name(node_id)
    GenServer.call(name, {:stop_command, command_ref})
  end

  @spec command_alive?(Grizzly.node_id() | pid(), reference()) :: boolean()
  def command_alive?(node_id, command_ref) do
    name = make_name(node_id)
    GenServer.call(name, {:command_alive?, command_ref})
  end

  defp make_name(pid) when is_pid(pid), do: pid
  defp make_name(node_id), do: Connections.make_name({:async, node_id})

  def stop(node_id) do
    # TODO close socket
    name = Connections.make_name({:async, node_id})
    GenServer.stop(name, :normal)
  catch
    :exit, {:noproc, _} -> :ok
  end

  @impl GenServer
  def init([grizzly_options, node_id, opts]) do
    owner = Keyword.fetch!(opts, :owner)
    host = ZIPGateway.host_for_node(node_id, grizzly_options)
    transport_impl = grizzly_options.transport

    transport_opts = [
      ip_address: host,
      port: grizzly_options.zipgateway_port,
      node_id: node_id
    ]

    ref = Process.monitor(owner)

    case Transport.open(transport_impl, transport_opts) do
      {:ok, transport} ->
        {:ok,
         %State{
           transport: transport,
           keep_alive: KeepAlive.init(node_id, 25_000),
           owner: owner,
           monitor_ref: ref,
           node_id: node_id
         }}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:send_command, command, send_opts}, {waiter, _ref}, state) do
    {:ok, command_runner, command_ref, new_command_list} =
      CommandList.create(state.commands, command, state.node_id, waiter, send_opts)

    case do_send_command(command_runner, state) do
      :ok ->
        {:reply, {:ok, command_ref},
         %State{
           state
           | commands: new_command_list,
             keep_alive: KeepAlive.timer_restart(state.keep_alive)
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

  @impl GenServer
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

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{monitor_ref: ref} = state) do
    # Connection's owner died, which means it's time to shut down
    {:stop, :normal, state}
  end

  def handle_info(data, state) do
    %State{transport: transport, node_id: node_id} = state

    case Transport.parse_response(transport, data) do
      {:ok, :connection_closed} ->
        Logger.debug("[Grizzly] connection to node #{inspect(node_id)} closed")
        {:stop, :normal, state}

      {:ok, transport_response} ->
        updated_state = handle_commands(transport_response.command, state)
        {:noreply, updated_state}

      {:error, error} ->
        error_message = Exception.message(error)
        Logger.warning("[Grizzly] #{inspect(error_message)}")
        {:noreply, state}
    end
  end

  defp handle_commands(%Command{name: :keep_alive}, state) do
    %State{state | keep_alive: KeepAlive.timer_restart(state.keep_alive)}
  end

  defp handle_commands(zip_packet, state) do
    case Command.param!(zip_packet, :flag) do
      :ack_request ->
        handle_ack_request(zip_packet, state)

      _ ->
        do_handle_commands(zip_packet, state)
    end
  end

  defp handle_ack_request(zip_packet, state) do
    %State{transport: transport} = state
    header_extensions = Command.param!(zip_packet, :header_extensions)
    seq_number = Command.param!(zip_packet, :seq_number)
    secure = Command.param!(zip_packet, :secure)
    command = Command.param!(zip_packet, :command)

    more_info =
      if command && command.name == :supervision_get do
        true
      else
        false
      end

    {:ok, ack_response} =
      ZIPPacket.new(
        secure: secure,
        header_extensions: header_extensions,
        seq_number: seq_number,
        more_info: more_info,
        flag: :ack_response
      )

    binary = ZWave.to_binary(ack_response)
    Transport.send(transport, binary)

    if command != nil do
      do_handle_commands(zip_packet, state)
    else
      state
    end
  end

  defp do_handle_commands(zip_packet, state) do
    updated_state =
      case CommandList.response_for_zip_packet(state.commands, zip_packet) do
        {:retry, command_runner, new_command_list} ->
          # TODO: this could be better, but do a little sleep between retries.
          # This is mostly for firmware updates.
          Process.sleep(100)

          :ok = do_send_command(command_runner, state)
          %State{state | commands: new_command_list}

        {:continue, new_command_list} ->
          if !ZIPPacket.ack_response?(zip_packet) do
            # Since we are doing async communications we need to handle when the
            # connection gets an unhandled command from the Z-Wave
            report = to_report(zip_packet, state.node_id)
            send(state.owner, {:grizzly, :report, report})
            Grizzly.Events.broadcast_report(report)
          end

          %State{state | commands: new_command_list}

        {waiter, {%Report{} = report, new_command_list}} ->
          send(waiter, {:grizzly, :report, report})
          Grizzly.Events.broadcast_report(report)
          %State{state | commands: new_command_list}
      end

    %State{updated_state | keep_alive: KeepAlive.timer_restart(state.keep_alive)}
  end

  defp to_report(zip_packet, node_id) do
    Report.new(:complete, :command, node_id, command: Command.param!(zip_packet, :command))
  end

  defp do_send_command(command_runner, state) do
    %State{transport: transport} = state
    binary = CommandRunner.encode_command(command_runner)

    Transport.send(transport, binary)
  end

  defp do_timeout_reply(waiter, grizzly_command) do
    if grizzly_command.status == :queued do
      report =
        Report.new(:complete, :timeout, grizzly_command.node_id,
          command_ref: grizzly_command.ref,
          acknowledged: grizzly_command.acknowledged,
          queued: true
        )

      send(waiter, {:grizzly, :report, report})
    else
      report =
        Report.new(:complete, :timeout, grizzly_command.node_id,
          command_ref: grizzly_command.ref,
          acknowledged: grizzly_command.acknowledged
        )

      send(waiter, {:grizzly, :report, report})
    end
  end
end
