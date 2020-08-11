defmodule Grizzly.Commands.CommandTest do
  use ExUnit.Case, async: true

  alias Grizzly.Report
  alias Grizzly.Commands.Command

  alias Grizzly.ZWave.CommandClasses.ZIP

  alias Grizzly.ZWave.Commands.{
    SwitchBinaryGet,
    SwitchBinaryReport,
    SwitchBinarySet,
    ZIPKeepAlive,
    ZIPPacket
  }

  alias Grizzly.CommandHandlers.AckResponse

  test "turns a Z-Wave command into a Grizzly command" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())

    expected_grizzly_command = %Command{
      handler: AckResponse,
      handler_state: nil,
      source: zwave_command,
      owner: self(),
      retries: 2,
      seq_number: grizzly_command.seq_number,
      ref: grizzly_command.ref,
      node_id: 1
    }

    assert expected_grizzly_command == grizzly_command
  end

  test "makes the Grizzly command into a binary" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())
    expected_binary = <<35, 2, 128, 80, grizzly_command.seq_number, 0, 0, 37, 1, 255>>

    assert expected_binary == Command.to_binary(grizzly_command)
  end

  test "handles Z/IP Packet for an ack response" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())

    ack_response = ZIPPacket.make_ack_response(grizzly_command.seq_number)

    report = Report.new(:complete, :ack_response, 1, command_ref: grizzly_command.ref)

    assert {report, %Command{grizzly_command | status: :complete}} ==
             Command.handle_zip_command(grizzly_command, ack_response)
  end

  test "handles Z/IP Packet for an report" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    {:ok, switch_report} = SwitchBinaryReport.new(target_value: :on)

    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())
    ack_response = ZIPPacket.make_ack_response(grizzly_command.seq_number)
    {:ok, zip_report} = ZIPPacket.with_zwave_command(switch_report, seq_number: 100)

    report =
      Report.new(:complete, :command, 1, command: switch_report, command_ref: grizzly_command.ref)

    assert {:continue, %Command{}} = Command.handle_zip_command(grizzly_command, ack_response)

    assert {report, %Command{grizzly_command | status: :complete}} ==
             Command.handle_zip_command(grizzly_command, zip_report)
  end

  test "handles Z/IP Packet for queued" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())

    nack_waiting = ZIPPacket.make_nack_waiting_response(grizzly_command.seq_number, 2)

    report =
      Report.new(:inflight, :queued_delay, 1,
        command_ref: grizzly_command.ref,
        queued_delay: 2,
        queued: true
      )

    assert {report, %Command{grizzly_command | status: :queued}} ==
             Command.handle_zip_command(grizzly_command, nack_waiting)
  end

  test "handles when a queued command is completed" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())
    grizzly_command = %Command{grizzly_command | status: :queued}

    ack_response = ZIPPacket.make_ack_response(grizzly_command.seq_number)

    report =
      Report.new(:complete, :ack_response, 1, command_ref: grizzly_command.ref, queued: true)

    assert {report, %Command{grizzly_command | status: :complete}} ==
             Command.handle_zip_command(grizzly_command, ack_response)
  end

  test "handles Z/IP Packet for nack response with retires" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self())

    nack_response = ZIPPacket.make_nack_response(grizzly_command.seq_number)

    expected_new_command = %Command{grizzly_command | retries: grizzly_command.retries - 1}

    assert {:retry, expected_new_command} ==
             Command.handle_zip_command(grizzly_command, nack_response)
  end

  test "handles Z/IP Packet for nack response with no retires" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, 1, self(), retries: 0)

    nack_response = ZIPPacket.make_nack_response(grizzly_command.seq_number)

    assert {:error, :nack_response, grizzly_command} ==
             Command.handle_zip_command(grizzly_command, nack_response)
  end

  test "if Z/IP keep alive command, does not encode as a Z/IP Packet" do
    {:ok, keep_alive} = ZIPKeepAlive.new(ack_flag: :ack_request)
    grizzly_command = Command.from_zwave_command(keep_alive, 1, self())
    expected_binary = <<ZIP.byte(), 0x03, 0x80>>

    assert expected_binary == Command.to_binary(grizzly_command)
  end
end
