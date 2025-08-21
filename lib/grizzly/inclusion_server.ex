defmodule Grizzly.InclusionServer do
  @moduledoc false

  # module for managing the inclusion state of the Z-Wave controller

  use GenServer

  alias Grizzly.{Inclusions, Report}
  alias Grizzly.Inclusions.StatusServer
  alias Grizzly.ZWave.{Command, DSK, Security}

  require Logger

  @doc """
  Start the inclusion server
  """
  @spec start_link(Grizzly.Options.t()) :: GenServer.on_start()
  def start_link(grizzly_opts) do
    GenServer.start_link(__MODULE__, grizzly_opts, name: __MODULE__)
  end

  @doc """
  Set the control into inclusion state
  """
  @spec add_node([Inclusions.opt()]) :: :ok | Inclusions.status()
  def add_node(opts) do
    opts = Keyword.put_new(opts, :handler, self())

    GenServer.call(__MODULE__, {:add_node, opts})
  end

  @doc """
  Stop the controller from being in the inclusion process
  """
  @spec add_node_stop() :: :ok | Inclusions.status()
  def add_node_stop() do
    GenServer.call(__MODULE__, :add_node_stop)
  end

  @doc """
  Set the controller to remove a Z-Wave device
  """
  @spec remove_node([Inclusions.opt()]) :: :ok | Inclusions.status()
  def remove_node(opts) do
    opts = Keyword.put_new(opts, :handler, self())

    GenServer.call(__MODULE__, {:remove_node, opts})
  end

  @doc """
  Stop the remove node process
  """
  @spec remove_node_stop() :: :ok | Inclusions.status()
  def remove_node_stop() do
    GenServer.call(__MODULE__, :remove_node_stop)
  end

  @doc """
  Set the controller to learn mode
  """
  @spec learn_mode([Inclusions.opt()]) :: :ok | Inclusions.status()
  def learn_mode(opts) do
    opts = Keyword.put_new(opts, :handler, self())

    GenServer.call(__MODULE__, {:learn_mode, opts})
  end

  @doc """
  Stop the controller from being in learn mode
  """
  @spec learn_mode_stop() :: :ok | Inclusions.status()
  def learn_mode_stop() do
    GenServer.call(__MODULE__, :learn_mode_stop)
  end

  @doc """
  Grant S2 keys during an inclusion
  """
  @spec grant_keys([Security.key()]) :: :ok | Inclusions.status()
  def grant_keys(s2_keys) do
    GenServer.call(__MODULE__, {:grant_s2_keys, s2_keys})
  end

  @doc """
  Set the input DSK
  """
  @spec set_input_dsk(DSK.t()) :: :ok | Inclusions.status()
  def set_input_dsk(input_dsk) do
    GenServer.call(__MODULE__, {:set_input_dsk, input_dsk})
  end

  @doc """
  Continues security bootstrapping for a node added by an inclusion controller.
  """
  @spec continue_inclusion(Grizzly.node_id(), Command.t()) :: :ok
  def continue_inclusion(node_id, command) do
    GenServer.call(__MODULE__, {:continue_inclusion, node_id, command})
  end

  @impl GenServer
  def init(grizzly_opts) do
    # check status and preform recovery steps if necessary

    adapter = grizzly_opts.inclusion_adapter

    {:ok, adapter_state} = adapter.init()

    state = %{
      adapter: adapter,
      default_handler: grizzly_opts.inclusion_handler,
      handler: nil,
      adapter_state: adapter_state,
      dsk_requested_length: 0
    }

    case StatusServer.get() do
      :idle ->
        Logger.debug("[Grizzly.InclusionServer] init status: :idle")
        {:ok, state}

      other_status ->
        # this happens if the inclusion server crashed in middle some type of
        # inclusion process. We will send the Z-Wave command to get the Z-Wave
        # control back into the normal operation state.
        #
        # If we do not do this the Z-Wave controller would think it is in an
        # inclusion process rendering it non-operable for operating Z-Wave
        # devices.
        Logger.debug("[Grizzly.InclusionServer] init status: #{inspect(other_status)}")
        {:ok, state, {:continue, {:cancel_inclusion, other_status}}}
    end
  end

  @impl GenServer
  def handle_continue({:cancel_inclusion, status}, state)
      when status in [:learn_mode, :learn_mode_stopping] do
    {:ok, new_state} = run_learn_mode_stop(state)

    {:noreply, new_state}
  end

  def handle_continue({:cancel_inclusion, status}, state)
      when status in [:node_removing, :node_remove_stopping] do
    {:ok, new_state} = run_remove_node_stop(state)

    {:noreply, new_state}
  end

  def handle_continue({:cancel_inclusion, status}, state)
      when status in [
             :node_adding,
             :waiting_dsk,
             :waiting_s2_keys,
             :s2_keys_granted,
             :dsk_input_set,
             :node_add_stopping
           ] do
    {:ok, new_state} = run_add_node_stop(state)

    {:noreply, new_state}
  end

  def handle_continue({:cancel_inclusion, status}, state) do
    Logger.warning("[Grizzly.InclusionServer] Unknown status at init: #{inspect(status)}")
    # if the status is currently in on of these the controller is already in the
    # process of going back to an operational state
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:add_node, opts}, _from, state) do
    with :idle <- StatusServer.get(),
         {:ok, new_adapter_state} <- state.adapter.add_node(state.adapter_state, opts) do
      state =
        state
        |> set_status(:node_adding)
        |> put_new_handler(opts)

      {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    else
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:remove_node, opts}, _from, state) do
    with :idle <- StatusServer.get(),
         {:ok, new_adapter_state} <- state.adapter.remove_node(state.adapter_state, opts) do
      state =
        state
        |> set_status(:node_removing)
        |> put_new_handler(opts)

      {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    else
      error ->
        {:reply, error, state}
    end
  end

  def handle_call(:add_node_stop, _from, state) do
    with status when status in [:node_adding, :waiting_s2_keys, :waiting_dsk] <-
           StatusServer.get(),
         {:ok, new_state} <- run_add_node_stop(state) do
      {:reply, :ok, new_state}
    else
      :idle -> {:reply, :ok, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(:remove_node_stop, _from, state) do
    with :node_removing <- StatusServer.get(),
         {:ok, new_state} <- run_remove_node_stop(state) do
      {:reply, :ok, new_state}
    else
      :idle -> {:reply, :ok, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call({:learn_mode, opts}, _from, state) do
    with :idle <- StatusServer.get(),
         {:ok, new_adapter_state} <- state.adapter.learn_mode(state.adapter_state, opts) do
      state =
        state
        |> set_status(:learn_mode)
        |> put_new_handler(opts)

      {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    else
      error -> {:reply, error, state}
    end
  end

  def handle_call(:learn_mode_stop, _from, state) do
    with :learn_mode <- StatusServer.get(),
         {:ok, new_state} <- run_learn_mode_stop(state) do
      {:reply, :ok, new_state}
    else
      :idle -> {:reply, :ok, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call({:grant_s2_keys, s2_keys}, _from, state) do
    with :waiting_s2_keys <- StatusServer.get(),
         {:ok, new_adapter_state} <- state.adapter.grant_s2_keys(s2_keys, state.adapter_state) do
      state = set_status(state, :s2_keys_granted)
      {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    else
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:set_input_dsk, dsk}, _from, state) do
    Logger.info(
      "[Grizzly.InclusionServer] Set input DSK (#{state.dsk_requested_length}): #{inspect(dsk)}"
    )

    with :waiting_dsk <- StatusServer.get(),
         {:ok, new_adapter_state} <-
           state.adapter.set_input_dsk(dsk, state.dsk_requested_length, state.adapter_state) do
      state = set_status(state, :dsk_input_set)

      {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    else
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:continue_inclusion, node_id, %Command{} = command}, _from, state) do
    {_, state} = handle_report(command, node_id, state)
    {:reply, :ok, state}
  end

  def handle_call(_, _from, state) do
    if StatusServer.get() == :idle do
      {:reply, :ok, state}
    else
      {:reply, {:error, :already_including}, state}
    end
  end

  @impl GenServer
  def handle_info({:grizzly, :report, %Report{type: :ack_response}}, state) do
    {:noreply, state}
  end

  def handle_info(
        {:grizzly, :report, %Report{type: :command, command: command, node_id: node_id}},
        state
      ) do
    handle_report(command, node_id, state)
  end

  def handle_info({:grizzly, :report, %Report{type: :timeout, command_ref: command_ref}}, state) do
    status = StatusServer.get()

    {new_server_status, new_adapter_state} =
      state.adapter.handle_timeout(status, command_ref, state.adapter_state)

    new_state = set_status(state, new_server_status)

    {:noreply, %{new_state | adapter_state: new_adapter_state}}
  end

  def handle_report(%Command{name: :node_remove_status} = command, node_id, state) do
    report = Report.new(:complete, :command, node_id, command: command)
    send_to_handler(state, report)

    state =
      state
      |> remove_handler()
      |> set_status(:idle)

    {:noreply, state}
  end

  def handle_report(%Command{name: name} = command, node_id, state)
      when name in [:node_add_status, :extended_node_add_status] do
    report = Report.new(:complete, :command, node_id, command: command)
    send_to_handler(state, report)

    state =
      state
      |> remove_handler()
      |> set_status(:idle)

    {:noreply, state}
  end

  def handle_report(%Command{name: :learn_mode_set_status} = command, node_id, state) do
    report = Report.new(:complete, :command, node_id, command: command)
    send_to_handler(state, report)

    state =
      state
      |> remove_handler()
      |> set_status(:idle)

    {:noreply, state}
  end

  def handle_report(%Command{name: :node_add_keys_report} = command, node_id, state) do
    report = Report.new(:complete, :command, node_id, command: command)
    send_to_handler(state, report)

    state = set_status(state, :waiting_s2_keys)

    {:noreply, state}
  end

  def handle_report(%Command{name: :node_add_dsk_report} = command, node_id, state) do
    requested_length = Command.param!(command, :input_dsk_length)

    report = Report.new(:complete, :command, node_id, command: command)
    send_to_handler(state, report)

    state = set_status(state, :waiting_dsk)

    Logger.info("[Grizzly.InclusionServer] DSK requested length: #{requested_length}")

    {:noreply, %{state | dsk_requested_length: requested_length}}
  end

  defp run_remove_node_stop(state) do
    case state.adapter.remove_node_stop(state.adapter_state) do
      {:ok, new_adapter_state} ->
        state = set_status(state, :node_remove_stopping)
        {:ok, %{state | adapter_state: new_adapter_state}}

      error ->
        {:reply, error, state}
    end
  end

  defp run_learn_mode_stop(state) do
    case state.adapter.learn_mode_stop(state.adapter_state) do
      {:ok, new_adapter_state} ->
        state = set_status(state, :learn_mode_stopping)
        {:ok, %{state | adapter_state: new_adapter_state}}

      error ->
        {:error, error}
    end
  end

  defp run_add_node_stop(state) do
    case state.adapter.add_node_stop(state.adapter_state) do
      {:ok, new_adapter_state} ->
        state = set_status(state, :node_add_stopping)
        {:ok, %{state | adapter_state: new_adapter_state}}

      error ->
        {:error, error}
    end
  end

  defp set_status(state, status) do
    :ok = StatusServer.set(status)

    state
  end

  defp remove_handler(state) do
    %{state | handler: nil}
  end

  defp put_new_handler(%{handler: nil} = state, opts) do
    %{state | handler: opts[:handler]}
  end

  defp put_new_handler(state, _opts) do
    state
  end

  defp send_to_handler(state, report) do
    do_send_to_handler(handler(state), report)
  end

  defp do_send_to_handler(nil, report) do
    Logger.debug("[Grizzly]: unhandled inclusion report: #{inspect(report)}")

    :ok
  end

  defp do_send_to_handler(handler, report) when is_pid(handler) do
    send(handler, {:grizzly, :report, report})
  end

  defp do_send_to_handler({handler, handler_opts}, report) when is_atom(handler) do
    send_to_module_handler(handler, report, handler_opts)
  end

  defp do_send_to_handler(handler, report) when is_atom(handler) do
    send_to_module_handler(handler, report, [])
  end

  defp send_to_module_handler(handler, report, opts) do
    spawn_link(fn -> handler.handle_report(report, opts) end)
  end

  defp handler(state) do
    state.handler || state.default_handler
  end
end
