defmodule Grizzly.Test do
  use ExUnit.Case

  alias Grizzly.Report
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.{SwitchBinaryGet, SwitchBinaryReport, ZIPPacket}

  import ExUnit.CaptureLog, only: [capture_log: 2]
  import Grizzly, only: [is_virtual_device: 1]

  describe "SwitchBinary Commands" do
    @tag :integration
    test "SwitchBinarySet version 1" do
      assert {:ok, %Report{status: :complete, type: :ack_response, node_id: 2}} =
               Grizzly.send_command(2, :switch_binary_set, target_value: :off)
    end

    @tag :integration
    test "SwitchBinarySet version 2" do
      assert {:ok, %Report{status: :complete, type: :ack_response, node_id: 2}} =
               Grizzly.send_command(2, :switch_binary_set, target_value: :on, duration: 100)
    end

    @tag :integration
    test "SWitchBinaryGet" do
      {:ok, switch_report} = SwitchBinaryReport.new(target_value: :off)

      assert {:ok,
              %Report{status: :complete, type: :command, command: ^switch_report, node_id: 2}} =
               Grizzly.send_command(2, :switch_binary_get)
    end
  end

  @tag :integration
  test "handles nack responses" do
    assert {:error, :nack_response} == Grizzly.send_command(101, :switch_binary_get)
  end

  @tag :integration
  test "command that timeouts" do
    assert {:ok, %Report{status: :complete, type: :timeout, node_id: 100}} =
             Grizzly.send_command(100, :switch_binary_get)
  end

  @tag :integration
  test "send a command to a node that hasn't been connected to yet" do
    {:ok, switch_report} = SwitchBinaryReport.new(target_value: :off)

    assert {:ok, %Report{status: :complete, type: :command, command: ^switch_report, node_id: 50}} =
             Grizzly.send_command(50, :switch_binary_get)
  end

  @tag :integration
  test "send a command to a device that is sleeping" do
    {:ok, %Report{queued_delay: 2, queued: true} = report} =
      Grizzly.send_command(102, :battery_get, [], timeout: 1000)

    assert is_reference(report.command_ref)
  end

  @tag :integration
  test "send a binary packet" do
    {:ok, switch_get} = SwitchBinaryGet.new()
    {:ok, packet} = ZIPPacket.with_zwave_command(switch_get, 0xA0)
    binary = Grizzly.ZWave.to_binary(packet)

    Grizzly.send_binary(3, binary)

    assert_receive {:grizzly, :binary_response, <<0x23, 0x2, 0x40, 0x10, 0xA0, 0x0, 0x0>>}

    assert_receive {:grizzly, :binary_response,
                    <<0x23, 0x2, 0x80, 0x50, _seq_no, 0x0, 0x0, 0x25, 0x3, 0x0>>}
  end

  @tag :integration
  test "handle garbage from Z-Wave network" do
    log = capture_log([], fn -> Grizzly.send_command(500, :door_lock_operation_get) end)

    assert String.contains?(log, "unexpected Z-Wave binary")
  end

  @tag :integration
  test "handles a command who contains a field that cannot be parsed" do
    log = capture_log([], fn -> Grizzly.send_command(501, :door_lock_operation_get) end)

    assert String.contains?(
             log,
             "unexpected value 0xAA for param :mode when decoding binary for :door_lock_operation_report"
           )
  end

  describe "version get" do
    test "association" do
      {:ok, report} =
        Grizzly.send_command(:gateway, :version_command_class_get, command_class: :association)

      assert Command.param!(report.command, :version) == 3
    end

    test "association group info" do
      {:ok, report} =
        Grizzly.send_command(:gateway, :version_command_class_get,
          command_class: :association_group_info
        )

      assert Command.param!(report.command, :version) == 1
    end

    test "device reset locally" do
      {:ok, report} =
        Grizzly.send_command(:gateway, :version_command_class_get,
          command_class: :device_reset_locally
        )

      assert Command.param!(report.command, :version) == 1
    end

    test "multi channel association" do
      {:ok, report} =
        Grizzly.send_command(:gateway, :version_command_class_get,
          command_class: :multi_channel_association
        )

      assert Command.param!(report.command, :version) == 4
    end

    test "supervision" do
      {:ok, report} =
        Grizzly.send_command(:gateway, :version_command_class_get, command_class: :supervision)

      assert Command.param!(report.command, :version) == 1
    end

    test "multi command" do
      {:ok, report} =
        Grizzly.send_command(:gateway, :version_command_class_get, command_class: :multi_command)

      assert Command.param!(report.command, :version) == 1
    end
  end

  describe "checking if a device id is a virtual devices" do
    test "when it is a virtual device" do
      id = {:virtual, 100}

      assert is_virtual_device(id)
      assert Grizzly.virtual_device?(id)
    end

    test "when it is not a virtual device" do
      refute is_virtual_device(100)
      refute Grizzly.virtual_device?(100)
    end

    test "when it is the gateway" do
      refute is_virtual_device(:gateway)
      refute Grizzly.virtual_device?(:gateway)
    end
  end

  describe "supervision" do
    test "success" do
      {:ok, report} =
        Grizzly.send_command(15, :door_lock_operation_set, [mode: :secured], supervision?: true)

      assert report.type == :command
      assert report.status == :complete

      assert [more_status_updates: :last_report, session_id: _, status: :success, duration: _] =
               report.command.params
    end

    test "multiple status updates when enabled" do
      {:ok, report} =
        Grizzly.send_command(700, :door_lock_operation_set, [mode: :secured],
          supervision?: true,
          status_updates?: true
        )

      assert report.type == :command
      assert report.status == :complete

      assert [more_status_updates: :last_report, session_id: _, status: :success, duration: _] =
               report.command.params

      assert_receive {:grizzly, :report,
                      %Grizzly.Report{
                        status: :inflight,
                        command: %Grizzly.ZWave.Command{
                          name: :supervision_report,
                          params: [
                            more_status_updates: :more_reports,
                            session_id: _,
                            status: :working,
                            duration: _
                          ]
                        },
                        node_id: 700,
                        type: :supervision_status,
                        queued: false
                      }}

      assert_receive {:grizzly, :report,
                      %Grizzly.Report{
                        status: :inflight,
                        command: %Grizzly.ZWave.Command{
                          name: :supervision_report,
                          params: [
                            more_status_updates: :more_reports,
                            session_id: _,
                            status: :working,
                            duration: _
                          ]
                        },
                        node_id: 700,
                        type: :supervision_status,
                        queued: false
                      }}

      refute_receive _
    end
  end

  test "no status updates if not enabled" do
    {:ok, report} =
      Grizzly.send_command(700, :door_lock_operation_set, [mode: :secured], supervision?: true)

    assert report.type == :command
    assert report.status == :complete

    assert [more_status_updates: :last_report, session_id: _, status: :success, duration: _] =
             report.command.params

    refute_receive _
  end

  describe "nack+waiting" do
    @tag :integration
    test "async nack_response when expected delay > timeout" do
      {:ok, %Report{command_ref: command_ref} = report} =
        Grizzly.send_command(800, :switch_binary_set, [target_value: :on], timeout: 1000)

      assert report.type == :queued_delay
      assert report.status == :inflight
      assert report.queued
      assert report.queued_delay == 3

      assert_receive {:grizzly, :report,
                      %Report{type: :nack_response, queued: true, command_ref: ^command_ref}},
                     3000
    end

    @tag :integration
    test "async ack when expected delay > timeout" do
      {:ok, %Report{command_ref: command_ref} = report} =
        Grizzly.send_command(801, :switch_binary_set, [target_value: :on], timeout: 1000)

      assert report.type == :queued_delay
      assert report.status == :inflight
      assert report.queued
      assert report.queued_delay == 3

      assert_receive {:grizzly, :report,
                      %Report{
                        type: :ack_response,
                        queued: true,
                        command_ref: ^command_ref,
                        command: nil
                      }},
                     2500
    end

    @tag :integration
    test "async report when expected delay > timeout" do
      {:ok, %Report{command_ref: command_ref} = report} =
        Grizzly.send_command(801, :switch_binary_get, [], timeout: 1000)

      assert report.type == :queued_delay
      assert report.status == :inflight
      assert report.queued
      assert report.queued_delay == 3

      assert_receive {:grizzly, :report,
                      %Report{
                        type: :command,
                        queued: true,
                        command_ref: ^command_ref,
                        command: %Command{name: :switch_binary_report}
                      }},
                     2500
    end

    @tag :integration
    test "sync nack_response when expected delay < timeout and response arrives in time" do
      assert {:error, :nack_response} =
               Grizzly.send_command(800, :switch_binary_set, [target_value: :on], timeout: 5000)
    end

    @tag :integration
    test "sync ack when expected delay < timeout and response arrives in time" do
      {:ok, report} =
        Grizzly.send_command(801, :switch_binary_set, [target_value: :on], timeout: 5000)

      assert report.type == :ack_response
      assert report.queued == false
      assert report.command == nil
    end

    @tag :integration
    test "sync report when expected delay < timeout and response arrives in time" do
      start = System.monotonic_time(:millisecond)
      {:ok, report} = Grizzly.send_command(801, :switch_binary_get, [], timeout: 5000)
      duration = System.monotonic_time(:millisecond) - start

      assert duration >= 1500

      assert report.type == :command
      assert report.queued == false
      assert report.command.name == :switch_binary_report
    end

    @tag :integration
    test "async timeout when expected delay < timeout and response arrives too late" do
      {:ok, report} = Grizzly.send_command(802, :switch_binary_get, [], timeout: 1000)

      assert report.type == :queued_delay
      assert report.status == :inflight
      assert report.queued
      assert report.queued_delay == 1

      command_ref = report.command_ref

      assert_receive {:grizzly, :report,
                      %Report{
                        type: :timeout,
                        queued: true,
                        command_ref: ^command_ref
                      }},
                     2000
    end

    # actual timeout, async case
    @tag :integration
    test "async timeout when expected delay < timeout but we never get a response" do
      {:ok, report} = Grizzly.send_command(803, :switch_binary_get, [], timeout: 500)

      assert report.type == :queued_delay
      assert report.status == :inflight
      assert report.queued

      command_ref = report.command_ref
      assert_receive {:grizzly, :report, %Report{type: :timeout, command_ref: ^command_ref}}, 2000
    end

    # actual timeout, sync case
    @tag :integration
    test "sync timeout when expected delay < timeout but we never get a response" do
      {:ok, report} = Grizzly.send_command(803, :switch_binary_get, [], timeout: 10000)

      assert report.type == :timeout
      assert report.status == :complete
      refute report.queued
    end

    @tag :integration
    test "additional nack_waiting frames extend the deadline and prevent timeouts" do
      start = System.monotonic_time(:millisecond)

      {:ok, report} =
        Grizzly.send_command(804, :switch_binary_set, [target_value: :on], timeout: 500)

      assert report.type == :queued_delay
      assert report.status == :inflight
      assert report.queued

      command_ref = report.command_ref

      # we only assert_receive two nack+waiting responses. the first one was what caused
      # Grizzly.send_command to return the queued_delay report. the second two will extend
      # the timer.
      assert_receive {:grizzly, :report, %Report{type: :queued_ping, command_ref: ^command_ref}},
                     1000

      assert_receive {:grizzly, :report, %Report{type: :queued_ping, command_ref: ^command_ref}},
                     1000

      assert_receive {:grizzly, :report, %Report{type: :ack_response, command_ref: ^command_ref}},
                     1000

      duration = System.monotonic_time(:millisecond) - start
      # node 804 sends 3 nack+waiting responses 750ms apart, so we should have spent at least
      # 2250ms waiting before getting the ack response
      assert duration >= 2250
    end
  end
end
