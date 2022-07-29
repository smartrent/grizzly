defmodule Grizzly.InclusionServer do
  @moduledoc false

  # module for managing the inclusion state of the Z-Wave controller

  use GenServer

  alias Grizzly.{Inclusions, Report}
  alias Grizzly.ZWave.{Command, DSK, Security}

  @typedoc """
  Status of the inclusion server
  """
  @type status() ::
          :idle
          | :node_adding
          | :node_add_stopping
          | :node_remove
          | :node_remove_stopping
          | :waiting_dsk
          | :waiting_s2_keys
          | :s2_keys_granted
          | :dsk_input_set

  defguardp is_idle(state) when state == :idle

  @doc """
  Start the inclusion server
  """
  @spec start_link(Grizzly.Options.t()) :: GenServer.on_start()
  def start_link(grizzly_opts) do
    GenServer.start_link(__MODULE__, grizzly_opts, name: __MODULE__)
  end

  @impl GenServer
  def init(grizzly_opts) do
    adapter = grizzly_opts.inclusion_adapter

    {:ok, adapter_state} = adapter.init()

    {:ok,
     %{
       state: :idle,
       adapter: adapter,
       handler: nil,
       adapter_state: adapter_state,
       dsk_requested_length: 0
     }}
  end

  @doc """
  Get the status of the inclusion server
  """
  @spec status() :: status()
  def status() do
    GenServer.call(__MODULE__, :status)
  end

  @doc """
  Set the control into inclusion state
  """
  @spec add_node([Inclusions.opt()]) :: :ok
  def add_node(opts) do
    opts = Keyword.put_new(opts, :handler, self())

    GenServer.call(__MODULE__, {:add_node, opts})
  end

  @doc """
  Stop the controller from being in the inclusion process
  """
  @spec add_node_stop() :: :ok
  def add_node_stop() do
    GenServer.call(__MODULE__, :add_node_stop)
  end

  @doc """
  Set the controller to remove a Z-Wave device
  """
  @spec remove_node([Inclusions.opt()]) :: :ok
  def remove_node(opts) do
    opts = Keyword.put_new(opts, :handler, self())

    GenServer.call(__MODULE__, {:remove_node, opts})
  end

  @doc """
  Stop the remove node process
  """
  @spec remove_node_stop() :: :ok
  def remove_node_stop() do
    GenServer.call(__MODULE__, :remove_node_stop)
  end

  @doc """
  Set the controller to learn mode
  """
  @spec learn_mode([Inclusions.opt()]) :: :ok
  def learn_mode(opts) do
    opts = Keyword.put_new(opts, :handler, self())

    GenServer.call(__MODULE__, {:learn_mode, opts})
  end

  @doc """
  Stop the controller from being in learn mode
  """
  @spec learn_mode_stop() :: :ok
  def learn_mode_stop() do
    GenServer.call(__MODULE__, :learn_mode_stop)
  end

  @doc """
  Grant S2 keys during an inclusion
  """
  @spec grant_keys([Security.key()]) :: :ok
  def grant_keys(s2_keys) do
    GenServer.call(__MODULE__, {:grant_s2_keys, s2_keys})
  end

  @doc """
  Set the input DSK
  """
  @spec set_input_dsk(DSK.t()) :: :ok
  def set_input_dsk(input_dsk) do
    GenServer.call(__MODULE__, {:set_input_dsk, input_dsk})
  end

  @impl GenServer
  def handle_call({:add_node, opts}, _from, %{state: status} = state) when is_idle(status) do
    :ok = state.adapter.connect(1)

    case state.adapter.add_node(state.adapter_state, opts) do
      {:ok, new_adapter_state} ->
        state =
          state
          |> set_state(:node_adding)
          |> put_new_handler(opts)

        {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    end
  end

  def handle_call({:remove_node, opts}, _from, %{state: status} = state) when is_idle(status) do
    :ok = state.adapter.connect(1)

    case state.adapter.remove_node(state.adapter_state, opts) do
      {:ok, new_adapter_state} ->
        state =
          state
          |> set_state(:node_removing)
          |> put_new_handler(opts)

        {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    end
  end

  def handle_call(:add_node_stop, _from, %{state: server_state} = state)
      when server_state in [:node_adding, :waiting_s2_keys, :waiting_dsk] do
    case state.adapter.add_node_stop(state.adapter_state) do
      {:ok, new_adapter_state} ->
        {:reply, :ok, %{state | state: :node_add_stopping, adapter_state: new_adapter_state}}
    end
  end

  def handle_call(:remove_node_stop, _from, %{state: :node_removing} = state) do
    case state.adapter.remove_node_stop(state.adapter_state) do
      {:ok, new_adapter_state} ->
        state = set_state(state, :node_remove_stopping)

        {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    end
  end

  def handle_call({:learn_mode, opts}, _from, state) do
    case state.adapter.learn_mode(state.adapter_state, opts) do
      {:ok, new_adapter_state} ->
        state =
          state
          |> set_state(:learn_mode)
          |> put_new_handler(opts)

        {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    end
  end

  def handle_call(:learn_mode_stop, _from, state) do
    case state.adapter.learn_mode_stop(state.adapter_state) do
      {:ok, new_adapter_state} ->
        state = set_state(state, :learn_mode_stopping)
        {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    end
  end

  def handle_call({:grant_s2_keys, s2_keys}, _from, %{state: :waiting_s2_keys} = state) do
    case state.adapter.grant_s2_keys(s2_keys, state.adapter_state) do
      {:ok, new_adapter_state} ->
        state = set_state(state, :s2_keys_granted)
        {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    end
  end

  def handle_call({:set_input_dsk, dsk}, _from, %{state: :waiting_dsk} = state) do
    case state.adapter.set_input_dsk(dsk, state.dsk_requested_length, state.adapter_state) do
      {:ok, new_adapter_state} ->
        state = set_state(state, :dsk_input_set)
        {:reply, :ok, %{state | adapter_state: new_adapter_state}}
    end
  end

  def handle_call(:status, _from, state) do
    {:reply, state.state, state}
  end

  def handle_call(_, _from, state) do
    if is_idle(state.state) do
      {:reply, :ok, state}
    else
      {:reply, {:error, :already_including}, state}
    end
  end

  @impl GenServer
  def handle_info({:grizzly, :report, %Report{type: :ack_response}}, state) do
    {:noreply, state}
  end

  def handle_info({:grizzly, :report, %Report{type: :command, command: command}}, state) do
    handle_report(command, state)
  end

  def handle_info({:grizzly, :report, %Report{type: :timeout, command_ref: command_ref}}, state) do
    {new_server_state, new_adapter_state} =
      state.adapter.handle_timeout(state.state, command_ref, state.adapter_state)

    new_state = set_state(state, new_server_state)

    {:noreply, %{new_state | adapter_state: new_adapter_state}}
  end

  def handle_report(%Command{name: :node_remove_status} = command, state) do
    report = Report.new(:complete, :command, 1, command: command)
    send_to_handler(state.handler, report)

    state =
      state
      |> remove_pid_handler()
      |> set_state(:idle)

    {:noreply, state}
  end

  def handle_report(%Command{name: :node_add_status} = command, state) do
    report = Report.new(:complete, :command, 1, command: command)
    send_to_handler(state.handler, report)

    state =
      state
      |> remove_pid_handler()
      |> set_state(:idle)

    {:noreply, state}
  end

  def handle_report(%Command{name: :learn_mode_set_status} = command, state) do
    report = Report.new(:complete, :command, 1, command: command)
    send_to_handler(state.handler, report)

    state =
      state
      |> remove_pid_handler()
      |> set_state(:idle)

    {:noreply, state}
  end

  def handle_report(%Command{name: :node_add_keys_report} = command, state) do
    report = Report.new(:complete, :command, 1, command: command)
    send_to_handler(state.handler, report)

    state = set_state(state, :waiting_s2_keys)

    {:noreply, state}
  end

  def handle_report(%Command{name: :node_add_dsk_report} = command, state) do
    requested_length = Command.param!(command, :input_dsk_length)

    report = Report.new(:complete, :command, 1, command: command)
    send_to_handler(state.handler, report)

    state = set_state(state, :waiting_dsk)

    {:noreply, %{state | dsk_requested_length: requested_length}}
  end

  defp set_state(server_state, inclusion_state) do
    %{server_state | state: inclusion_state}
  end

  defp remove_pid_handler(%{handler: handler} = state) when is_pid(handler) do
    %{state | handler: nil}
  end

  defp remove_pid_handler(state), do: state

  defp put_new_handler(%{handler: nil} = state, opts) do
    %{state | handler: opts[:handler]}
  end

  defp put_new_handler(state, _opts) do
    state
  end

  def send_to_handler(handler, report) when is_pid(handler) do
    send(handler, {:grizzly, :report, report})
  end

  def send_to_handler({handler, handler_opts}, report) when is_atom(handler) do
    handler.handle_report(report, handler_opts)
  end

  def send_to_handler(handler, report) when is_atom(handler) do
    handler.handle_report(report, [])
  end
end
