defmodule Grizzly.ZWave.Commands.ZIPPacketTest do
  use ExUnit.Case

  alias Grizzly.ZWave.Commands.{ZIPPacket, SwitchBinarySet}

  test "from binary ack response" do
    binary = <<0x23, 0x02, 0x40, 0x10, 0x10, 0x00, 0x00>>

    expected_packet = %ZIPPacket{
      command: nil,
      flag: :ack_response,
      seq_number: 0x10,
      source: 0x00,
      dest: 0x00,
      header_extensions: [],
      secure: true
    }

    assert {:ok, expected_packet} == ZIPPacket.from_binary(binary)
  end

  test "make a ZIPPacket with a command" do
    {:ok, command} = SwitchBinarySet.new(target_value: :off)
    zip_packet = ZIPPacket.with_zwave_command(command, seq_number: 0xAB)

    assert command == zip_packet.command
    assert :ack_request == zip_packet.flag
  end

  test "a ack_request requires a Z-Wave command" do
    binary = <<0x23, 0x02, 0x80, 0x10, 0x23, 0x00, 0x00, 0x00>>

    assert {:error, :invalid_zip_packet, :missing_zwave_command} == ZIPPacket.from_binary(binary)
  end

  test "an ack cannot have a nack with it" do
    binary = <<0x23, 0x02, 0xA0, 0x10, 0x10, 0x00, 0x00, 0x00>>

    assert {:error, :invalid_zip_packet, :flags} == ZIPPacket.from_binary(binary)
  end

  test "an ack request requires a command, and can parse the command" do
    {:ok, expected_command} = SwitchBinarySet.new(target_value: :off)
    binary = <<0x23, 0x02, 0x80, 0x50, 0x25, 0x00, 0x00, 0x25, 0x01, 0x00>>

    expected_zip_packet = %ZIPPacket{
      command: expected_command,
      flag: :ack_request,
      seq_number: 0x25,
      source: 0x00,
      dest: 0x00,
      header_extensions: [],
      secure: true
    }

    assert {:ok, expected_zip_packet} == ZIPPacket.from_binary(binary)
  end
end
