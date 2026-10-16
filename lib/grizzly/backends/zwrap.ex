defmodule Grizzly.Backends.Zwrap do
  @moduledoc """
  Direct Z-Wave controller backend. Owns one process-isolated Zwrap controller.

  Grizzly command handlers run before Z/IP encapsulation. This backend translates
  local controller commands to the public Zwrap API; device commands are sent as
  raw command-class bytes. See `docs/backends.md` for capabilities and limitations.
  """
  use GenServer

  alias Grizzly.Backends.Zwrap.Connection, as: NativeConnection
  alias Grizzly.Backends.Zwrap.Directory
  alias Grizzly.Backends.Zwrap.Mailbox
  alias Grizzly.Backends.Zwrap.Management
  alias Grizzly.Backends.Zwrap.Statistics
  alias Grizzly.Report
  alias Grizzly.UnsolicitedServer.ResponseHandler
  alias Grizzly.ZWave

  require Grizzly.NodeId
  require Logger

  @spec start_link(Grizzly.Options.t()) :: GenServer.on_start()
  def start_link(options), do: GenServer.start_link(__MODULE__, options, name: __MODULE__)

  @doc "Whether the native controller finished initialization."
  @spec ready?() :: boolean()
  def ready?() do
    GenServer.call(__MODULE__, :ready?)
  catch
    :exit, _ -> false
  end

  @doc "The owned controller, for core operations with no Grizzly equivalent."
  @spec controller() :: GenServer.server()
  def controller(), do: GenServer.call(__MODULE__, :controller)

  @doc "Actual controller identity and negotiated payload capacity."
  def identity(), do: GenServer.call(__MODULE__, :identity)

  @doc false
  def register_session(node, endpoint, commands),
    do: GenServer.call(__MODULE__, {:session, node, endpoint, commands})

  @doc false
  def directory_options(), do: GenServer.call(__MODULE__, :directory_options)

  @doc false
  def submit(node_id, command, ref, attempt, opts) do
    GenServer.call(__MODULE__, {:submit, node_id, command, ref, attempt, opts}, 30_000)
  catch
    :exit, _ -> {:error, :backend_down}
  end

  @doc false
  def submit_for(owner, node, command, ref, attempt, opts) do
    GenServer.call(__MODULE__, {:submit_for, owner, node, command, ref, attempt, opts}, 30_000)
  end

  @doc false
  def finish_wake(node), do: GenServer.call(__MODULE__, {:finish_wake, node})

  @doc false
  def release(pid, ref), do: GenServer.cast(__MODULE__, {:release, pid, ref})

  @doc false
  def route_command(node_id, command, candidates, endpoint) do
    GenServer.cast(__MODULE__, {:route, node_id, command, candidates, endpoint})
  end

  @doc false
  def children(options) do
    [
      Statistics,
      Mailbox,
      {__MODULE__, options},
      %{id: Directory, start: {__MODULE__, :start_directory, []}}
    ]
  end

  @doc false
  def post_children(_), do: []
  @doc false
  def start_directory(), do: Directory.start_link(directory_options())
  @doc false
  def connection_spec(node, opts) do
    if Keyword.get(opts, :mode) == :binary do
      {:error, :unsupported_backend_operation}
    else
      {:ok, NativeConnection.child_spec(node, Keyword.put_new(opts, :owner, self()))}
    end
  end

  @doc false
  def zipgateway_operation(_), do: {:error, :unsupported_backend_operation}
  @doc false
  def controller_id(), do: identity().controller_id

  @doc "Current Home ID in the same uppercase hexadecimal form as the legacy facade."
  def home_id() do
    GenServer.call(__MODULE__, :home_id)
  catch
    :exit, _ -> nil
  end

  @doc "Export assigned network keys to the caller only, never to event subscribers."
  def network_keys() do
    GenServer.call(__MODULE__, :network_keys)
  catch
    :exit, _ -> nil
  end

  @doc false
  def zniffer_network_keys() do
    GenServer.call(__MODULE__, :zniffer_network_keys)
  catch
    :exit, _ -> nil
  end

  @doc false
  def listening_mode(node) when Grizzly.NodeId.is_virtual_node_id(node),
    do: {:ok, :always_listening}

  def listening_mode(node) do
    case Directory.get_node(node) do
      {:ok, %{mode: flags}} ->
        mode =
          case flags[:mode] do
            :always_listening -> :always_listening
            :flirs -> :frequently_listening
            mode when mode in [:wakeup, :wakeup_firmware_upgrade] -> :wakeup
            _ -> :unknown
          end

        {:ok, mode}

      _ ->
        nil
    end
  catch
    :exit, _ -> nil
  end

  defp initialization_options(options, opts) do
    top = options |> Map.take(Zwrap.InitSettings.keys()) |> Enum.to_list()
    requested = Zwrap.InitSettings.from_options!(top)
    nested = Zwrap.InitSettings.from_options!(opts)

    for {key, value} <- requested, Map.has_key?(nested, key), nested[key] != value do
      raise ArgumentError, "conflicting Grizzly/Zwrap initialization setting: #{key}"
    end

    Keyword.merge(
      Keyword.drop(opts, Zwrap.InitSettings.keys()),
      Map.to_list(Map.merge(requested, nested))
    )
  end

  @impl GenServer
  def init(options) do
    {api, opts} = Keyword.pop(options.zwrap_options, :api, Zwrap)
    opts = Keyword.put_new(opts, :serial_port, options.serial_port)
    opts = initialization_options(options, opts)

    if Code.ensure_loaded?(api) do
      paths = Module.concat([Zwrap, Controller]).resolve_core_paths(opts)
      path = paths.core_database_path

      with false <- File.exists?(Directory.journal(path)),
           {:ok, controller} <- api.start_link(opts),
           :ok <- api.subscribe(controller),
           {:ok,
            <<2, controller_id::16, max_payload::16, home_id::binary-size(4), _operations::32>>} <-
             api.control(controller, :capabilities, []) do
        Grizzly.Events.broadcast_event(:ready, true)

        {:ok,
         %{
           api: api,
           controller: controller,
           pending: [],
           monitors: %{},
           operations: %{},
           controller_id: controller_id,
           max_payload: max_payload,
           home_id: home_id,
           path: path,
           fault: nil,
           sessions: %{}
         }}
      else
        true -> {:stop, :directory_recovery_required}
        error -> {:stop, error}
      end
    else
      {:stop, :zwrap_dependency_not_available}
    end
  end

  @impl GenServer
  def handle_call(:ready?, _from, state),
    do: {:reply, is_nil(state.fault) and not File.exists?(Directory.journal(state.path)), state}

  def handle_call(:identity, _from, state),
    do: {:reply, Map.take(state, [:controller_id, :max_payload, :home_id]), state}

  def handle_call(:directory_options, _from, state),
    do: {:reply, [path: state.path, api: state.api, controller: &__MODULE__.controller/0], state}

  def handle_call(:home_id, _from, state) do
    case state.api.control(state.controller, :capabilities, []) do
      {:ok, <<2, id::16, max::16, home::binary-size(4), _ops::32>>} ->
        {:reply, Base.encode16(home),
         %{state | controller_id: id, max_payload: max, home_id: home}}

      _ ->
        {:reply, nil, state}
    end
  end

  def handle_call(:zniffer_network_keys, _from, state) do
    result =
      with {:ok, %{home_id: home} = keys} <- state.api.get_network_keys(state.controller),
           true <- is_binary(home) and byte_size(home) == 4 do
        Grizzly.NetworkKeys.zniffer(Base.encode16(home), Grizzly.NetworkKeys.from_native(keys))
      else
        {:error, _} = error -> error
        _ -> {:error, :identity_unavailable}
      end

    {:reply, result, state}
  end

  def handle_call(:network_keys, _from, state) do
    result =
      with {:ok, keys} <- state.api.get_network_keys(state.controller) do
        Grizzly.NetworkKeys.from_native(keys)
      end

    {:reply, result, state}
  end

  def handle_call(:controller, _from, state), do: {:reply, state.controller, state}

  def handle_call({:session, node, endpoint, commands}, {pid, _}, state) do
    state = monitor_client(state, pid)
    session = %{node: node, endpoint: endpoint, commands: commands}
    {:reply, :ok, put_in(state.sessions[pid], session)}
  end

  def handle_call({:finish_wake, node}, _from, state) do
    result =
      with {:ok, <<1>>} <- state.api.control(state.controller, :idle, []) do
        state.api.send_data_appl(state.controller, node, <<0x84, 0x08>>, nil)
      else
        _ -> {:error, :busy}
      end

    {:reply, result, state}
  end

  def handle_call({:submit, node_id, command, ref, attempt, opts}, {pid, _}, state),
    do: submit_entry(pid, node_id, command, ref, attempt, opts, state)

  def handle_call({:submit_for, pid, node_id, command, ref, attempt, opts}, _from, state),
    do: submit_entry(pid, node_id, command, ref, attempt, opts, state)

  defp submit_entry(pid, node_id, command, ref, attempt, opts, state) do
    entry = %{
      pid: pid,
      ref: ref,
      attempt: attempt,
      node_id: node_id,
      endpoint: Keyword.get(opts, :destination, 0),
      command: command
    }

    result =
      cond do
        not is_nil(state.fault) ->
          {:error, :backend_fault}

        Management.local?(command) and node_id not in [:gateway, state.controller_id] ->
          {:error, :unsupported_backend_operation}

        Management.local?(command) and entry.endpoint != 0 ->
          {:error, :unsupported_backend_option}

        Management.local?(command) ->
          Management.submit(state, entry)

        node_id == :gateway ->
          {:error, :unsupported_backend_command}

        true ->
          send_application(state, entry)
      end

    case result do
      {:ok, state} ->
        state = monitor_client(state, pid)
        # Retain the registration until the request handler completes, not just
        # until TX completion: GET, aggregate and Supervision handlers need RX.
        pending = Enum.reject(state.pending, &(&1.pid == pid and &1.ref == ref))
        {:reply, :ok, %{state | pending: pending ++ [entry]}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_cast({:release, pid, ref}, state) do
    state = release_request(state, pid, ref)
    {:noreply, state}
  end

  def handle_cast({:route, node_id, command, candidates, endpoint}, state) do
    route(node_id, command, candidates, endpoint, state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:zwrap, :send_data_appl_complete, %{context: {pid, ref, attempt}} = fields},
        state
      ) do
    if Enum.any?(state.pending, &(&1.pid == pid and &1.ref == ref and &1.attempt == attempt)) do
      entry =
        Enum.find(state.pending, &(&1.pid == pid and &1.ref == ref and &1.attempt == attempt))

      kind = if fields.status in [:ok, :verified], do: :tx_success, else: :tx_failure
      Statistics.record(entry.node_id, kind, fields[:tx_report])

      if fields.status in [:ok, :verified] do
        send(pid, {:backend_ack, ref, attempt, fields[:tx_report]})
      else
        send(pid, {:backend_failure, ref, attempt, fields.status})
      end
    end

    {:noreply, state}
  end

  def handle_info({:zwrap, :unsolicited_frame_received, fields}, state) do
    Grizzly.Trace.log(fields.node_id, :grizzly, fields.frame)
    Grizzly.Events.broadcast_event(:raw_frame, fields)
    Statistics.record(fields.node_id, :rx)

    case decode_frame(fields.frame) do
      {:ok, command} ->
        if command.name == :wake_up_notification,
          do: Mailbox.wake(fields.node_id)

        candidates =
          Enum.filter(
            state.pending,
            &(&1.node_id == fields.node_id and
                &1.endpoint == Map.get(fields, :source_endpoint, 0))
          )

        route(fields.node_id, command, candidates, Map.get(fields, :source_endpoint, 0), state)

      {:error, _} ->
        Logger.warning("[Grizzly.Zwrap] Ignoring undecodable application frame")
    end

    {:noreply, state}
  end

  def handle_info({:zwrap, :tx_observation, fields}, state) do
    Statistics.record_native(fields)
    Grizzly.Events.broadcast_event(:native_event, %{event: :tx_observation, fields: fields})
    {:noreply, state}
  end

  def handle_info({:zwrap, :maintenance_fault, fields}, state) do
    Grizzly.Events.broadcast_event(:ready, false)
    {:noreply, %{state | fault: fields.reason}}
  end

  def handle_info({:zwrap, :port_exit, _reason}, state), do: {:stop, :native_port_exit, state}

  def handle_info({:zwrap, event, fields}, state) do
    Grizzly.Events.broadcast_event(:native_event, %{event: event, fields: fields})
    {:noreply, Management.handle_event(state, event, fields)}
  end

  def handle_info({:DOWN, monitor, :process, pid, _reason}, state) do
    if state.monitors[pid] == monitor do
      refs = state.pending |> Enum.filter(&(&1.pid == pid)) |> Enum.map(& &1.ref)
      state = Enum.reduce(refs, state, &release_request(&2, pid, &1))

      {:noreply,
       %{
         state
         | monitors: Map.delete(state.monitors, pid),
           sessions: Map.delete(state.sessions, pid)
       }}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def terminate(_reason, state) do
    if Process.alive?(state.controller), do: GenServer.stop(state.controller)
  end

  defp send_application(state, entry) do
    payload = ZWave.to_binary(entry.command)
    endpoint = entry.endpoint

    cond do
      not is_integer(endpoint) or endpoint not in 0..127 ->
        {:error, :unsupported_backend_option}

      not (entry.node_id in 1..232 or entry.node_id in 256..4000) ->
        {:error, :invalid_node_id}

      byte_size(payload) + if(endpoint == 0, do: 0, else: 4) > state.max_payload ->
        {:error, :payload_too_large}

      true ->
        payload =
          if endpoint == 0, do: payload, else: <<0x60, 0x0D, 0, endpoint, payload::binary>>

        Grizzly.Trace.log(:grizzly, entry.node_id, payload)

        case state.api.send_data_appl(
               state.controller,
               entry.node_id,
               payload,
               {entry.pid, entry.ref, entry.attempt}
             ) do
          :ok -> {:ok, state}
          error -> error
        end
    end
  rescue
    _error in [ArgumentError, FunctionClauseError, MatchError, KeyError] ->
      {:error, :invalid_backend_argument}
  end

  defp decode_frame(frame) do
    ZWave.from_binary(frame)
  rescue
    _error -> {:error, :invalid_frame}
  end

  defp monitor_client(state, pid) do
    if Map.has_key?(state.monitors, pid),
      do: state,
      else: put_in(state.monitors[pid], Process.monitor(pid))
  end

  defp release_request(state, pid, ref) do
    pending = Enum.reject(state.pending, &(&1.pid == pid and &1.ref == ref))

    # Keep context-free native operations reserved after caller timeout/death.
    # Only their actual callback may free the slot; otherwise a late callback
    # could complete a newer request of the same type.
    state = %{state | pending: pending}

    if Enum.any?(pending, &(&1.pid == pid)) or Map.has_key?(state.sessions, pid) do
      state
    else
      case Map.pop(state.monitors, pid) do
        {nil, _} ->
          state

        {monitor, monitors} ->
          Process.demonitor(monitor, [:flush])
          %{state | monitors: monitors}
      end
    end
  end

  defp route(node_id, command, [entry | rest], endpoint, state) do
    if Process.alive?(entry.pid) do
      send(entry.pid, {:backend_command, entry.ref, node_id, command, rest, endpoint})
    else
      route(node_id, command, rest, endpoint, state)
    end
  end

  defp route(node_id, command, [], endpoint, state) do
    for {pid, session} <- state.sessions,
        session.node == node_id and session.endpoint == endpoint and
          command.name in session.commands do
      send(pid, {:backend_session, command})
    end

    # Response actions may call back into the backend, so execute them outside
    # its mailbox (e.g. Supervision replies and association/version requests).
    Task.Supervisor.start_child(Grizzly.TaskSupervisor, fn ->
      case ResponseHandler.handle_application_command(node_id, command) do
        actions when is_list(actions) -> Enum.each(actions, &run_action(node_id, &1, endpoint))
        _ -> :ok
      end
    end)
  end

  defp run_action(node_id, {:notify, command}, _endpoint) do
    Grizzly.Events.broadcast_report(Report.unsolicited(node_id, command))
  end

  defp run_action(node_id, {:send, command}, endpoint) do
    # A reply doesn't need another request handler; still send raw CC bytes.
    controller = controller()
    api = Grizzly.options().zwrap_options[:api] || Zwrap
    payload = ZWave.to_binary(command)
    payload = if endpoint == 0, do: payload, else: <<0x60, 0x0D, 0, endpoint, payload::binary>>
    Grizzly.Trace.log(:grizzly, node_id, payload)
    api.send_data_appl(controller, node_id, payload, nil)
  end

  defp run_action(_node_id, {:forward_to_controller, _command}, _endpoint), do: :ok
  defp run_action(_node_id, _action, _endpoint), do: :ok
end
