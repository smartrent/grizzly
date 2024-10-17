defmodule Grizzly.Test do
  use ExUnit.Case, async: false

  alias Grizzly.Report
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.{SwitchBinaryGet, SwitchBinaryReport, ZIPPacket}

  import ExUnit.CaptureLog, only: [capture_log: 2]

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
    test "SwitchBinaryGet" do
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
  test "nack response to queued command (via sync connection)" do
    test_queued_nack_response_handling(:sync)
  end

  @tag :integration
  test "nack response to queued command (via async connection)" do
    test_queued_nack_response_handling(:async)
  end

  defp test_queued_nack_response_handling(mode) do
    assert {:ok,
            %Grizzly.Report{
              status: :inflight,
              type: :queued_delay,
              queued: true,
              command_ref: ref
            }} =
             Grizzly.send_command(103, :switch_binary_set, [target_value: :on], mode: mode)

    assert_receive {:grizzly, :report,
                    %Grizzly.Report{status: :inflight, type: :queued_ping, command_ref: ^ref}}

    assert_receive {:grizzly, :report,
                    %Grizzly.Report{status: :complete, type: :nack_response, command_ref: ^ref}}
  end

  @tag :integration
  test "nack queue full (via sync connection)" do
    assert {:error, :queue_full} = Grizzly.send_command(104, :switch_binary_get)
  end

  @tag :integration
  test "nack queue full (via async connection)" do
    assert {:ok, %Grizzly.Report{queued: true, command_ref: ref}} =
             Grizzly.send_command(104, :switch_binary_get, [], mode: :async)

    assert_receive {:grizzly, :report,
                    %Grizzly.Report{status: :complete, type: :queue_full, command_ref: ^ref}}
  end

  @tag :integration
  test "command that times out" do
    assert {:ok, %Report{status: :complete, type: :timeout, node_id: 100}} =
             Grizzly.send_command(100, :switch_binary_get, [], timeout: 500)
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
      Grizzly.send_command(102, :battery_get)

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
    log =
      capture_log([], fn ->
        Grizzly.send_command(500, :door_lock_operation_get, [], timeout: 500)
      end)

    assert String.contains?(log, "unexpected Z-Wave binary")
  end

  @tag :integration
  test "handles a command who contains a field that cannot be parsed" do
    log = capture_log([], fn -> Grizzly.send_command(501, :door_lock_operation_get) end)

    assert String.contains?(
             log,
             "Unexpected value for door lock mode: 170"
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

      assert Command.param!(report.command, :version) == 3
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
        Grizzly.send_command(:gateway, :version_command_class_get, command_class: :multi_cmd)

      assert Command.param!(report.command, :version) == 1
    end
  end

  describe "checking if a device id is a virtual devices" do
    test "when it is a virtual device" do
      assert Grizzly.virtual_device?({:virtual, 100})
    end

    test "when it is not a virtual device" do
      refute Grizzly.virtual_device?(100)
    end

    test "when it is the gateway" do
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
end
