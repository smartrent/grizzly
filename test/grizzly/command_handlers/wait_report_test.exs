defmodule Grizzly.CommandHandlers.WaitReportTest do
  use ExUnit.Case

  setup do
    Grizzly.Trace.clear()

    on_exit(fn ->
      Grizzly.Connection.close(203)
      Grizzly.Trace.clear()
    end)
  end

  test "orders reports correctly when a get command implements report_matches_get?/2" do
    task1 =
      Task.async(fn ->
        Grizzly.send_command(203, :version_command_class_get, command_class: :alarm)
      end)

    task2 =
      Task.async(fn ->
        # wait 100ms before to ensure the first task completes first
        Process.sleep(100)
        Grizzly.send_command(203, :version_command_class_get, command_class: :door_lock)
      end)

    [{:ok, %{command: report1}}, {:ok, %{command: report2}}] = Task.await_many([task1, task2])

    assert [command_class: :alarm, version: 1] == report1.params
    assert [command_class: :door_lock, version: 2] == report2.params

    literal_packets =
      Grizzly.Trace.list()
      # Filter out packets that are not relevant to the test. Needed because
      # BackgroundRSSIMonitor is running and sending RSSI Get commands to node 1.
      |> Enum.reject(&(&1.src == 1 or &1.dest == 1))
      |> Enum.map(&binary_slice(&1.binary, 7..-1//1))
      |> Enum.reject(&(&1 == ""))

    assert literal_packets == [
             <<134, 19, 113>>,
             <<134, 19, 98>>,
             <<134, 20, 98, 2>>,
             <<134, 20, 113, 1>>
           ]
  end
end
