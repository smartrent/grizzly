defmodule Grizzly.ZIPGateway.SAPIMonitorTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZIPGateway.SAPIMonitor

  setup %{test: test} do
    test_pid = self()
    Grizzly.Events.subscribe(:serial_api_status)

    opts = [
      name: test,
      status_reporter: fn status -> send(test_pid, status) end
    ]

    %{monitor_opts: opts}
  end

  test "transition into unresponsive status", %{monitor_opts: opts} do
    pid =
      start_supervised!({SAPIMonitor, Keyword.merge(opts, period: 250, threshold: 5)})

    assert :ok = SAPIMonitor.status(pid)
    assert_received :ok
    assert_receive {:grizzly, :serial_api_status, :ok}

    SAPIMonitor.retransmission(pid)
    SAPIMonitor.retransmission(pid)
    SAPIMonitor.retransmission(pid)
    SAPIMonitor.retransmission(pid)

    assert :ok = SAPIMonitor.status(pid)

    SAPIMonitor.retransmission(pid)
    assert :unresponsive = SAPIMonitor.status(pid)
    assert_received :unresponsive
    assert_receive {:grizzly, :serial_api_status, :unresponsive}
  end

  test "transition out of unresponsive status automatically", %{monitor_opts: opts} do
    pid =
      start_supervised!({SAPIMonitor, Keyword.merge(opts, period: 250, threshold: 5)})

    assert :ok = SAPIMonitor.status(pid)
    assert_received :ok

    SAPIMonitor.retransmission(pid)
    SAPIMonitor.retransmission(pid)
    SAPIMonitor.retransmission(pid)
    SAPIMonitor.retransmission(pid)
    SAPIMonitor.retransmission(pid)

    assert :unresponsive = SAPIMonitor.status(pid)
    assert_received :unresponsive
    assert_receive {:grizzly, :serial_api_status, :unresponsive}

    assert_receive :ok, 500
    assert :ok = SAPIMonitor.status(pid)
    assert_receive {:grizzly, :serial_api_status, :ok}
  end
end
