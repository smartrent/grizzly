defmodule Grizzly.Connections.SyncConnection do
  @moduledoc false

  # Module for establishing a "connection" to a Z-Wave Node

  use GenServer

  alias Grizzly.Connections
  alias Grizzly.Connections.KeepAlive
  alias Grizzly.Connections.RequestList
  alias Grizzly.Options
  alias Grizzly.Report
  alias Grizzly.Requests.RequestRunner
  alias Grizzly.Transport
  alias Grizzly.ZIPGateway
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands

  require Logger

  @type send_opt() :: {:timeout, non_neg_integer()} | {:retries, non_neg_integer()}

  defmodule State do
    @moduledoc false
    defstruct transport: nil,
              requests: RequestList.empty(),
              keep_alive: nil,
              node_id: nil
  end

  def child_spec(node_id, opts \\ []) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [node_id, opts]}, restart: :transient}
  end

  @doc """
  Start connection to a device or the Z/IP Gateway
  """
  @spec start_link(Options.t(), ZWave.node_id() | :gateway, [Grizzly.command_opt()]) ::
          GenServer.on_start()
  def start_link(grizzly_options, node_id_or_gateway, opts \\ []) do
    unnamed = Keyword.get(opts, :unnamed, false)

    start_opts =
      if unnamed do
        []
      else
        [name: Connections.via_name(node_id_or_gateway)]
      end

    GenServer.start_link(__MODULE__, [grizzly_options, node_id_or_gateway, opts], start_opts)
  end

  @spec send_command(ZWave.node_id() | pid(), Command.t(), [send_opt()]) ::
          Grizzly.send_command_response()
  def send_command(node_id, command, opts \\ []) do
    name = Connections.via_name(node_id)
    GenServer.call(name, {:send_command, command, node_id, opts}, 140_000)
  end

  @doc """
  Close the connection
  """
  @spec close(ZWave.node_id() | pid()) :: :ok
  def close(node_id_or_pid) do
    name = Connections.via_name(node_id_or_pid)
    # when stop this process the socket port that is owned
    # this process gets cleaned up for us.
    GenServer.stop(name, :normal)
  end

  @impl GenServer
  def init([grizzly_options, node_id_or_gateway, _opts]) do
    host = ZIPGateway.host_for_node(node_id_or_gateway, grizzly_options)
    transport_impl = grizzly_options.transport

    transport_opts = [
      ip_address: host,
      port: grizzly_options.zipgateway_port,
      node_id: node_id_or_gateway
    ]

    case Transport.open(transport_impl, transport_opts) do
      {:ok, transport} ->
        {:ok,
         %State{
           transport: transport,
           keep_alive: KeepAlive.init(node_id_or_gateway, 25_000),
           node_id: node_id_or_gateway
         }}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:send_command, command, _node_id, command_opts}, from, %State{} = state) do
    {:ok, request_runner, _, new_request_list} =
      RequestList.create(state.requests, command, state.node_id, from, command_opts)

    case do_send_command(request_runner, state) do
      :ok ->
        {:noreply,
         %State{
           state
           | requests: new_request_list,
             keep_alive: KeepAlive.timer_restart(state.keep_alive)
         }}
    end
  end

  @impl GenServer
  def handle_info(:keep_alive_tick, %State{} = state) do
    %State{keep_alive: keep_alive} = state

    new_keep_alive =
      keep_alive
      |> KeepAlive.make_command()
      |> KeepAlive.run(&do_send_command(&1, state, trace: false))

    {:noreply, %State{state | keep_alive: new_keep_alive}}
  end

  # handle when there is a timeout and command runner stops
  def handle_info(
        {:grizzly, :command_timeout, request_runner_pid, request},
        %State{} = state
      ) do
    if request.source.name == :keep_alive do
      {:noreply, state}
    else
      waiter = RequestList.get_waiter_for_runner(state.requests, request_runner_pid)
      do_timeout_reply(waiter, request)

      {:noreply,
       %State{
         state
         | requests: RequestList.drop_request_runner(state.requests, request_runner_pid)
       }}
    end
  end

  def handle_info(data, state) do
    %State{transport: transport, node_id: node_id} = state

    case Transport.parse_response(transport, data) do
      {:ok, :connection_closed} ->
        Logger.debug("[Grizzly] connection to node #{inspect(node_id)} closed")
        {:stop, :normal, state}

      {:ok, command} ->
        new_state = handle_commands(command, state)
        {:noreply, new_state}

      {:error, error} ->
        error_message = Exception.message(error)
        Logger.warning("[Grizzly] #{inspect(error_message)}")
        {:noreply, state}
    end
  end

  defp handle_commands(%Command{name: :keep_alive}, %State{} = state) do
    %State{state | keep_alive: KeepAlive.timer_restart(state.keep_alive)}
  end

  defp handle_commands(zip_packet, state) do
    Logger.debug("Recv Z/IP Packet: #{inspect(zip_packet)}")

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
      Commands.create(:zip_packet,
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

  defp do_handle_commands(zip_packet, %State{} = state) do
    updated_state =
      case RequestList.response_for_zip_packet(state.requests, zip_packet) do
        {:retry, request_runner, new_request_list} ->
          :ok = do_send_command(request_runner, state)
          %State{state | requests: new_request_list}

        {:continue, new_request_list} ->
          %State{state | requests: new_request_list}

        {waiter, {%Report{} = report, new_request_list}} when is_pid(waiter) ->
          send(waiter, {:grizzly, :report, report})
          Grizzly.Events.broadcast_report(report)
          %State{state | requests: new_request_list}

        {waiter, {%Report{} = report, new_request_list}} ->
          GenServer.reply(waiter, {:ok, report})
          Grizzly.Events.broadcast_report(report)
          %State{state | requests: new_request_list}
      end

    %State{updated_state | keep_alive: KeepAlive.timer_restart(state.keep_alive)}
  end

  defp do_send_command(command, state, opts \\ []) do
    %State{transport: transport} = state
    binary = RequestRunner.encode_command(command)

    Transport.send(transport, binary, opts)
  end

  defp do_timeout_reply(waiter, request) do
    if request.status == :queued do
      {pid, _tag} = waiter

      report =
        Report.new(:complete, :timeout, request.node_id,
          command_ref: request.ref,
          acknowledged: request.acknowledged,
          queued: true
        )

      send(pid, {:grizzly, :report, report})
    else
      report =
        Report.new(:complete, :timeout, request.node_id,
          command_ref: request.ref,
          acknowledged: request.acknowledged
        )

      GenServer.reply(waiter, {:ok, report})
    end
  end
end
