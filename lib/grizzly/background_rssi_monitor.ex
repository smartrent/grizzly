defmodule Grizzly.BackgroundRSSIMonitor do
  @moduledoc """
  Monitors the background RSSI on all Z-Wave channels and raises an alarm if it
  exceeds a configurable threshold.
  """

  use GenServer

  require Logger

  @alarm_id Grizzly.HighBackgroundRSSIAlarm

  @default_classic_threshold -97
  @default_lr_threshold -90

  @default_sample_interval :timer.seconds(5)

  # Average over 6 samples, which is ~30 seconds at the default sample interval
  @history_size 6

  @type opt ::
          {:classic_threshold, integer()}
          | {:lr_threshold, integer()}
          | {:sample_interval, integer() | false}
          | {:name, GenServer.name()}

  @doc false
  @spec __sample__(GenServer.server()) :: :ok
  def __sample__(server \\ __MODULE__) do
    GenServer.call(server, :sample)
  end

  @doc """
  Returns the average background RSSI values over the configured sampling period.
  """
  @spec get_averages(GenServer.server()) :: [
          {:channels, [number()]},
          {:long_range_primary_channel, number()},
          {:long_range_secondary_channel, number()}
        ]
  def get_averages(server \\ __MODULE__) do
    GenServer.call(server, :get_averages)
  end

  @spec start_link([opt()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    classic_threshold = Keyword.get(opts, :classic_threshold, @default_classic_threshold)
    lr_threshold = Keyword.get(opts, :lr_threshold, @default_lr_threshold)
    sample_interval = Keyword.get(opts, :sample_interval, @default_sample_interval)
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(
      __MODULE__,
      [
        classic_threshold: classic_threshold,
        lr_threshold: lr_threshold,
        sample_interval: sample_interval
      ],
      name: name
    )
  end

  @impl GenServer
  def init(opts) do
    _ =
      if opts[:sample_interval] != false do
        Process.send_after(self(), :sample, opts[:sample_interval])
      end

    {:ok,
     %{
       classic_threshold: opts[:classic_threshold],
       lr_threshold: opts[:lr_threshold],
       sample_interval: opts[:sample_interval],
       history: CircularBuffer.new(@history_size)
     }}
  end

  @impl GenServer
  def handle_call(:sample, _from, state) do
    {status, state} = do_sample(state)
    {:reply, status, state}
  end

  def handle_call(:get_averages, _from, state) do
    [ch0, ch1, ch2, lr_primary, lr_secondary] = calculate_averages(state.history)

    {:reply,
     {:ok,
      [
        channels: [maybe_round(ch0), maybe_round(ch1), maybe_round(ch2)],
        long_range_primary_channel: maybe_round(lr_primary),
        long_range_secondary_channel: maybe_round(lr_secondary)
      ]}, state}
  end

  @impl GenServer
  def handle_info(:sample, state) do
    {status, state} = do_sample(state)

    if status == :ok do
      Process.send_after(self(), :sample, state.sample_interval)
    else
      Process.send_after(self(), :sample, state.sample_interval * 3)
    end

    {:noreply, state}
  end

  defp do_sample(state) do
    case get_sample() do
      {:ok, sample} ->
        state = %{state | history: CircularBuffer.insert(state.history, sample)}
        set_or_clear_alarm(state)
        {:ok, state}

      {:error, reason} when reason in [:including, :firmware_updating] ->
        {:error, state}

      {:error, reason} ->
        Logger.warning(
          "[Grizzly.BackgroundRSSIMonitor] Failed to get background RSSI sample: #{inspect(reason)}"
        )

        {:error, state}
    end
  end

  defp set_or_clear_alarm(state) do
    [ch0, ch1, ch2, lr_primary, lr_secondary] = calculate_averages(state.history)

    if (is_number(ch0) and ch0 >= state.classic_threshold) or
         (is_number(ch1) and ch1 >= state.classic_threshold) or
         (is_number(ch2) and ch2 >= state.classic_threshold) or
         (is_number(lr_primary) and lr_primary >= state.lr_threshold) or
         (is_number(lr_secondary) and lr_secondary >= state.lr_threshold) do
      :alarm_handler.set_alarm({@alarm_id, []})
    else
      :alarm_handler.clear_alarm(@alarm_id)
    end
  end

  defp calculate_averages(history) do
    Enum.zip_with(history, fn values ->
      # Filter out non-numeric values (:rssi_not_available) as well as -128. It's
      # not documented anywhere, but from testing, it appears that the serial api
      # will return -128 when it is unable to determine the RSSI (possibly due to
      # the radio not being in receive mode for too long or something similar).
      valid_values = Enum.filter(values, &(is_number(&1) and &1 != -128))

      if valid_values == [] do
        # If no valid values, return a default value
        :rssi_not_available
      else
        # Return the average of the valid values
        Enum.sum(valid_values) / length(valid_values)
      end
    end)
  end

  defp get_sample() do
    case Grizzly.background_rssi() do
      {:ok, result} ->
        [ch0, ch1, ch2] =
          Keyword.get(result, :channels, [
            :rssi_not_available,
            :rssi_not_available,
            :rssi_not_available
          ])

        lr_primary = Keyword.get(result, :long_range_primary_channel, :rssi_not_available)
        lr_secondary = Keyword.get(result, :long_range_secondary_channel, :rssi_not_available)
        {:ok, [ch0, ch1, ch2, lr_primary, lr_secondary]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_round(v) when is_number(v), do: round(v)
  defp maybe_round(v), do: v
end
