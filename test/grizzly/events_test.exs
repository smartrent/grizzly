defmodule Grizzly.EventsTest do
  use ExUnit.Case, async: false

  alias Grizzly.{Events, Report}
  alias Grizzly.ZWave.Commands.{AlarmReport, BasicReport, WakeUpIntervalReport}

  test "finding subscribers that match a particular report" do
    Supervisor.terminate_child(Grizzly.Supervisor, Grizzly.FirmwareUpdates.OTWUpdateRunner)
    Supervisor.terminate_child(Grizzly.Supervisor, Grizzly.Storage.CommandWatcher)

    on_exit(fn ->
      Supervisor.restart_child(Grizzly.Supervisor, Grizzly.FirmwareUpdates.OTWUpdateRunner)
      Supervisor.restart_child(Grizzly.Supervisor, Grizzly.Storage.CommandWatcher)
    end)

    test_pid = self()

    pid1 =
      spawn_link(fn ->
        Events.subscribe([1, {:virtual, 1}, :basic_report, :wake_up_interval_report])
        send(test_pid, :subscribed)
        Process.sleep(:infinity)
      end)

    pid2 =
      spawn_link(fn ->
        Events.subscribe([2], firehose: true)
        send(test_pid, :subscribed)
        Process.sleep(:infinity)
      end)

    pid3 =
      spawn_link(fn ->
        Events.subscribe(3)
        Events.subscribe(:wake_up_interval_report, firehose: true)
        send(test_pid, :subscribed)
        Process.sleep(:infinity)
      end)

    pid4 =
      spawn_link(fn ->
        Events.subscribe({:virtual, 2}, firehose: true)
        send(test_pid, :subscribed)
        Process.sleep(:infinity)
      end)

    # ensure the spawned processes have started and subscribed
    assert_receive :subscribed
    assert_receive :subscribed
    assert_receive :subscribed
    assert_receive :subscribed

    {:ok, basic_report} = BasicReport.new(value: :on)
    {:ok, wake_up_interval_report} = WakeUpIntervalReport.new([])
    {:ok, alarm_report} = AlarmReport.new([])

    assert [^pid1] = Events.__subs_for_report__(Report.unsolicited(1, basic_report))
    assert [^pid1] = Events.__subs_for_report__(Report.unsolicited({:virtual, 1}, basic_report))

    subscribers = Events.__subs_for_report__(Report.unsolicited(2, basic_report))
    assert length(subscribers) == 2
    assert pid1 in subscribers
    assert pid2 in subscribers

    assert [^pid2] = Events.__subs_for_report__(Report.command(2, basic_report))

    subscribers =
      Events.__subs_for_report__(Report.unsolicited(2, wake_up_interval_report))

    assert length(subscribers) == 3
    assert pid1 in subscribers
    assert pid2 in subscribers
    assert pid3 in subscribers

    subscribers = Events.__subs_for_report__(Report.command(2, wake_up_interval_report))
    assert length(subscribers) == 2
    assert pid2 in subscribers
    assert pid3 in subscribers

    subscribers = Events.__subs_for_report__(Report.unsolicited(3, basic_report))
    assert length(subscribers) == 2
    assert pid1 in subscribers
    assert pid3 in subscribers

    assert [] = Events.__subs_for_report__(Report.command(3, basic_report))

    assert [^pid4] = Events.__subs_for_report__(Report.unsolicited({:virtual, 2}, alarm_report))
    assert [^pid4] = Events.__subs_for_report__(Report.command({:virtual, 2}, alarm_report))
  end
end
