defmodule Grizzly.Test do
  use ExUnit.Case

  alias Grizzly.Report
  alias Grizzly.ZWave.Commands.SwitchBinaryReport

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
      Grizzly.send_command(102, :battery_get)

    assert is_reference(report.command_ref)
  end
end
