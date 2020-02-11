defmodule Grizzly.Commands.CommandTest do
  use ExUnit.Case, async: true

  alias Grizzly.Commands.Command
  alias Grizzly.ZWave.Commands.{SwitchBinaryGet, SwitchBinaryReport, SwitchBinarySet, ZIPPacket}
  alias Grizzly.ZWave.CommandHandlers.AckResponse

  test "turns a Z-Wave command into a Grizzly command" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)

    grizzly_command = Command.from_zwave_command(zwave_command, self())

    expected_grizzly_command = %Command{
      handler: AckResponse,
      handler_state: nil,
      source: zwave_command,
      owner: self(),
      retries: 2,
      seq_number: grizzly_command.seq_number,
      ref: grizzly_command.ref
    }

    assert expected_grizzly_command == grizzly_command
  end

  test "makes the Grizzly command into a binary" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)
    grizzly_command = Command.from_zwave_command(zwave_command, self())
    expected_binary = <<35, 2, 128, 80, grizzly_command.seq_number, 0, 0, 37, 1, 255>>

    assert expected_binary == Command.to_binary(grizzly_command)
  end

  test "handles Z/IP Packet for an ack response" do
    {:ok, zwave_command} = SwitchBinarySet.new(target_value: :on)
    grizzly_command = Command.from_zwave_command(zwave_command, self())

    ack_response = ZIPPacket.make_ack_response(grizzly_command.seq_number)

    assert {:complete, :ok} == Command.handle_zip_packet(grizzly_command, ack_response)
  end

  test "handles Z/IP Packet for an report" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    {:ok, report} = SwitchBinaryReport.new(target_value: :on)

    grizzly_command = Command.from_zwave_command(zwave_command, self())
    ack_response = ZIPPacket.make_ack_response(grizzly_command.seq_number)
    zip_report = ZIPPacket.with_zwave_command(report, seq_number: 100)

    assert {:continue, %Command{}} = Command.handle_zip_packet(grizzly_command, ack_response)

    assert {:complete, {:ok, report}} == Command.handle_zip_packet(grizzly_command, zip_report)
  end

  test "handles Z/IP Packet for queued" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, self())

    nack_waiting = ZIPPacket.make_nack_waiting_response(2, grizzly_command.seq_number)

    assert {:queued, 2, grizzly_command} ==
             Command.handle_zip_packet(grizzly_command, nack_waiting)
  end

  test "handles Z/IP Packet for nack response with retires" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, self())

    nack_response = ZIPPacket.make_nack_response(grizzly_command.seq_number)

    expected_new_command = %Command{grizzly_command | retries: grizzly_command.retries - 1}

    assert {:retry, expected_new_command} ==
             Command.handle_zip_packet(grizzly_command, nack_response)
  end

  test "handles Z/IP Packet for nack response with no retires" do
    {:ok, zwave_command} = SwitchBinaryGet.new()
    grizzly_command = Command.from_zwave_command(zwave_command, self(), nil, retries: 0)

    nack_response = ZIPPacket.make_nack_response(grizzly_command.seq_number)

    assert {:error, :nack_response, grizzly_command} ==
             Command.handle_zip_packet(grizzly_command, nack_response)
  end
end
