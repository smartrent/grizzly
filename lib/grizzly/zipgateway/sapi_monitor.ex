defmodule Grizzly.ZIPGateway.SAPIMonitor do
  @moduledoc false

  use GenServer

  @type serial_api_status :: :ok | :unresponsive

  @type option ::
          {:period, pos_integer()}
          | {:threshold, pos_integer()}
          | {:name, GenServer.name()}

  # There must be THRESHOLD retransmissions within the last PERIOD milliseconds for
  # the SAPI status to be considered unresponsive. This prevents occasional SAPI
  # blips from accumulating and causing a false positive unresponsive status.
  @default_period :timer.seconds(30)
  @default_threshold 5

  @spec retransmission(GenServer.name()) :: :ok
  def retransmission(name \\ __MODULE__) do
    GenServer.call(name, :retransmission)
  end

  @spec status(GenServer.name()) :: serial_api_status()
  def status(name \\ __MODULE__) do
    GenServer.call(name, :status)
  end

  @spec reset(GenServer.name()) :: :ok
  def reset(name \\ __MODULE__) do
    GenServer.call(name, :reset)
  end

  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    default_period = Application.get_env(:grizzly, :sapi_monitor_period, @default_period)
    default_threshold = Application.get_env(:grizzly, :sapi_monitor_threshold, @default_threshold)

    period = Keyword.get(opts, :period, default_period)
    threshold = Keyword.get(opts, :threshold, default_threshold)

    GenServer.start_link(
      __MODULE__,
      [period: period, threshold: threshold],
      name: name
    )
  end

  @impl GenServer
  def init(opts) do
    period = Keyword.fetch!(opts, :period)
    threshold = Keyword.fetch!(opts, :threshold)

    state = %{
      period: period,
      threshold: threshold,
      retransmissions: [],
      status: :ok,
      check_timer: nil
    }

    notify(:ok)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:retransmission, _from, state) do
    state = %{
      state
      | retransmissions: [System.monotonic_time(:millisecond) | state.retransmissions]
    }

    {:reply, :ok, update(state)}
  end

  def handle_call(:status, _from, state) do
    state = update(state)
    {:reply, state.status, state}
  end

  def handle_call(:reset, _from, state) do
    state = %{state | retransmissions: []}
    {:reply, :ok, update(state)}
  end

  @impl GenServer
  def handle_info(:check, state) do
    {:noreply, update(state)}
  end

  defp update(state) do
    state = %{state | retransmissions: drop_old(state.retransmissions, state.period)}

    if length(state.retransmissions) >= state.threshold do
      state
      |> set_status(:unresponsive)
      |> clear_timer()
      |> schedule_check()
    else
      set_status(state, :ok)
    end
  end

  defp set_status(state, new_status) do
    maybe_notify(state, new_status)
    %{state | status: new_status}
  end

  defp clear_timer(state) do
    case state.check_timer do
      nil ->
        state

      check_timer ->
        _ = Process.cancel_timer(check_timer, info: false)
        %{state | check_timer: nil}
    end
  end

  defp schedule_check(state) do
    # If there are any retransmissions in the current state, set a new timer to
    # check again in PERIOD + 10 milliseconds
    ref = Process.send_after(self(), :check, state.period + 10)
    %{state | check_timer: ref}
  end

  # If status has not changed, do not notify
  defp maybe_notify(%{status: status}, status), do: :ok

  defp maybe_notify(_state, new_status) do
    notify(new_status)
  end

  defp notify(status) do
    Grizzly.Events.broadcast_event(:serial_api_status, status)

    :ok
  end

  # Drop retransmissions older than PERIOD milliseconds
  defp drop_old(retransmissions, period) do
    Enum.reject(retransmissions, fn timestamp ->
      System.monotonic_time(:millisecond) - timestamp > period
    end)
  end
end
