defmodule Grizzly.BackgroundRSSIMonitorTest do
  use ExUnit.Case, async: true
  use Mimic.DSL

  alias Grizzly.BackgroundRSSIMonitor

  test "calculating averages", ctx do
    pid =
      start_link_supervised!({BackgroundRSSIMonitor, [name: ctx.test, sample_interval: false]})

    allow(Grizzly, self(), pid)

    expect Grizzly.background_rssi(),
      do:
        {:ok,
         samples(
           :rssi_not_available,
           :rssi_not_available,
           :rssi_not_available,
           :rssi_not_available,
           :rssi_not_available
         )}

    expect Grizzly.background_rssi(), do: {:ok, samples(1, 2, 3, 4, 5)}
    expect Grizzly.background_rssi(), do: {:ok, samples(4, 3, 2, 1, :rssi_not_available)}
    expect Grizzly.background_rssi(), do: {:ok, samples(1, 2, 3, 4, 5)}

    :ok = BackgroundRSSIMonitor.__sample__(pid)
    :ok = BackgroundRSSIMonitor.__sample__(pid)
    :ok = BackgroundRSSIMonitor.__sample__(pid)
    :ok = BackgroundRSSIMonitor.__sample__(pid)

    {:ok, averages} = BackgroundRSSIMonitor.get_averages(pid)

    assert averages == [
             channels: [2, 2, 3],
             long_range_primary_channel: 3,
             long_range_secondary_channel: 5
           ]
  end

  test "sets and clears alarms", ctx do
    pid =
      start_link_supervised!({BackgroundRSSIMonitor, [name: ctx.test, sample_interval: false]})

    # Alarmist.subscribe(Grizzly.HighBackgroundRSSIAlarm)
    allow(Grizzly, self(), pid)

    expect Grizzly.background_rssi(),
      num_calls: 2,
      do: {:ok, samples(-104, -104, -104, -98, :rssi_not_available)}

    expect Grizzly.background_rssi(),
      num_calls: 2,
      do: {:ok, samples(-90, -104, -104, -98, -128)}

    BackgroundRSSIMonitor.__sample__(pid)
    BackgroundRSSIMonitor.__sample__(pid)
    BackgroundRSSIMonitor.__sample__(pid)
    refute Grizzly.HighBackgroundRSSIAlarm in Alarmist.get_alarm_ids()

    BackgroundRSSIMonitor.__sample__(pid)
    Process.sleep(20)
    assert Grizzly.HighBackgroundRSSIAlarm in Alarmist.get_alarm_ids()

    {:ok, averages} = BackgroundRSSIMonitor.get_averages(pid)

    assert averages == [
             channels: [-97, -104, -104],
             long_range_primary_channel: -98,
             long_range_secondary_channel: :rssi_not_available
           ]
  end

  defp samples(ch0, ch1, ch2, lr_primary, lr_secondary) do
    [
      channels: [ch0, ch1, ch2],
      long_range_primary_channel: lr_primary,
      long_range_secondary_channel: lr_secondary
    ]
  end
end
