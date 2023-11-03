defmodule Grizzly.ZIPGateway.LogMonitorTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZIPGateway.LogMonitor

  setup %{test: test} do
    test_pid = self()

    pid =
      start_supervised!(
        {LogMonitor,
         [
           name: test,
           status_reporter: fn status -> send(test_pid, status) end
         ]}
      )

    %{monitor_pid: pid}
  end

  test "extracts home id", %{monitor_pid: pid} do
    assert nil == LogMonitor.home_id(pid)

    send(pid, {:message, "ZIP_Router_Reset: pan_lladdr: cb:f4:32:d0:00:01  Home ID = 0xd032f4cb"})

    assert "D032F4CB" == LogMonitor.home_id(pid)
  end

  test "extracts network keys", %{monitor_pid: pid} do
    assert [] = LogMonitor.network_keys(pid)

    send(pid, {:message, "Key class 0x80: KEY_CLASS_S0"})
    send(pid, {:message, "D5F14A0691D62E20F4CA5DB7109D6580"})

    assert [s0: "D5F14A0691D62E20F4CA5DB7109D6580"] = LogMonitor.network_keys(pid)

    send(pid, {:message, "Key class 0x80: KEY_CLASS_S0_FAKE"})
    send(pid, {:message, "ABCDEF0123456789ABCDEF0123456789"})

    assert [s0: "D5F14A0691D62E20F4CA5DB7109D6580"] = LogMonitor.network_keys(pid)

    send(pid, {:message, "Key class 0x01: KEY_CLASS_S2_UNAUTHENTICATED"})
    send(pid, {:message, "A6B760276792A18359C8733D316B70C8"})

    assert [
             s2_unauthenticated: "A6B760276792A18359C8733D316B70C8",
             s0: "D5F14A0691D62E20F4CA5DB7109D6580"
           ] = LogMonitor.network_keys(pid)
  end

  test "extracts all from full log", %{monitor_pid: pid} do
    logs =
      """
      Initializing S0
      Key class 0x80: KEY_CLASS_S0
      D5F14A0691D62E20F4CA5DB7109D6580
      sec0_set_key
      Key class 0x01: KEY_CLASS_S2_UNAUTHENTICATED
      A6B760276792A18359C8733D316B70C8
      Key class 0x02: KEY_CLASS_S2_AUTHENTICATED
      6DAC33D245333E8A4BCF73096A2D6000
      Key class 0x04: KEY_CLASS_S2_ACCESS
      CD92279CAAEB5EBAC39DBE85AA803859
      Key class 0x08: KEY_CLASS_S2_AUTHENTICATED_LR
      E132670AE97B5584529EA5F7FCA52637
      Key class 0x10: KEY_CLASS_S2_ACCESS_LR
      A0F71EE40E5DEB55E34C71ECEBB73168
      Network scheme is: SECURITY_SCHEME_2_ACCESS
      Resetting IMA
      Indicator blink script from config file (not sanitized): /srv/erlang/lib/grizzly-6.4.0/priv/indicator.sh
      Using indicator blink script: /srv/erlang/lib/grizzly-6.4.0/priv/indicator.sh
      I'm a primary or inclusion controller.
      Command classes updated
       nodeid=1 0x00
      Waiting for bridge
      ZIP_Router_Reset: pan_lladdr: cb:f4:32:d0:00:01  Home ID = 0xd032f4cb
      """
      |> String.split("\n")

    for log <- logs do
      send(pid, {:message, log})
    end

    assert "D032F4CB" == LogMonitor.home_id(pid)
    network_keys = LogMonitor.network_keys(pid)

    assert "D5F14A0691D62E20F4CA5DB7109D6580" = Keyword.get(network_keys, :s0)
    assert "A6B760276792A18359C8733D316B70C8" = Keyword.get(network_keys, :s2_unauthenticated)
    assert "6DAC33D245333E8A4BCF73096A2D6000" = Keyword.get(network_keys, :s2_authenticated)
    assert "CD92279CAAEB5EBAC39DBE85AA803859" = Keyword.get(network_keys, :s2_access_control)

    assert "E132670AE97B5584529EA5F7FCA52637" =
             Keyword.get(network_keys, :s2_authenticated_long_range)

    assert "A0F71EE40E5DEB55E34C71ECEBB73168" =
             Keyword.get(network_keys, :s2_access_control_long_range)
  end

  describe "serial api status reporting" do
    test "reports ok on successful init", %{monitor_pid: pid} do
      send(pid, {:message, "Serial Process init"})
      assert :initializing == LogMonitor.serial_api_status(pid)

      send(pid, {:message, "Bridge init done"})
      assert :ok == LogMonitor.serial_api_status(pid)
    end

    test "reports unresponsive after 5 retransmissions", %{monitor_pid: pid} do
      send(pid, {:message, "Serial Process init"})
      assert :initializing == LogMonitor.serial_api_status(pid)
      assert_received :initializing

      send(pid, {:message, "Bridge init done"})
      assert :ok == LogMonitor.serial_api_status(pid)
      assert_received :ok

      send(pid, {:message, " SerialAPI: Retransmission 0 of 0x07"})
      send(pid, {:message, " SerialAPI: Retransmission 1 of 0x07"})
      send(pid, {:message, " SerialAPI: Retransmission 2 of 0x07"})
      send(pid, {:message, " SerialAPI: Retransmission 3 of 0x07"})
      assert :ok == LogMonitor.serial_api_status(pid)

      send(pid, {:message, " SerialAPI: Retransmission 4 of 0x07"})
      assert :unresponsive == LogMonitor.serial_api_status(pid)
      assert_received :unresponsive
    end
  end
end
