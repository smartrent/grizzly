defmodule Grizzly.ZWave.Commands.ZIPPacketTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.SwitchBinarySet
  alias Grizzly.ZWave.Commands.ZIPPacket

  describe "creating a new Z/IP Packet command" do
    test "with defaults" do
      {:ok, command} = ZIPPacket.new()

      assert Command.param!(command, :source) == 0x00
      assert Command.param!(command, :dest) == 0x00
      assert Command.param!(command, :flag) == nil
      assert Command.param!(command, :command) == nil
      assert Command.param!(command, :header_extensions) == []
    end

    test "with a Z-Wave command" do
      {:ok, switch_set} = SwitchBinarySet.new(target_value: :on)
      {:ok, zip_packet} = ZIPPacket.new(command: switch_set)

      assert Command.param!(zip_packet, :command) == switch_set
    end

    test "create a Z/IP command with a Z-Wave command, default flag to :ack_response, secure true" do
      {:ok, switch_set} = SwitchBinarySet.new(target_value: :off)
      {:ok, command} = ZIPPacket.with_zwave_command(switch_set, 0x10)

      assert Command.param!(command, :command) == switch_set
      assert Command.param!(command, :seq_number) == 0x10
      assert Command.param!(command, :secure) == true
      assert Command.param!(command, :flag) == :ack_request
    end
  end

  describe "decoding params" do
    test "ack response, no headers, no command" do
      binary_params = <<0x40, 0x10, 0x10, 0x00, 0x00>>

      {:ok, decoded_params} = ZIPPacket.decode_params(binary_params)

      assert Keyword.fetch!(decoded_params, :flag) == :ack_response
      assert Keyword.fetch!(decoded_params, :seq_number) == 0x10
      assert Keyword.fetch!(decoded_params, :secure) == true
    end

    test "nak waiting for 3 seconds" do
      binary_params = <<0x30, 0x90, 0x01, 0x00, 0x00, 0x06, 0x01, 0x03, 0x00, 0x00, 0x03>>

      {:ok, decoded_params} = ZIPPacket.decode_params(binary_params)

      assert Keyword.fetch!(decoded_params, :flag) == :nack_waiting
      assert Keyword.fetch!(decoded_params, :seq_number) == 0x01
      assert Keyword.fetch!(decoded_params, :header_extensions) == [{:expected_delay, 3}]
    end
  end

  describe "encoding commands" do
    test "when there is no command" do
      {:ok, command} = ZIPPacket.new(seq_number: 0x10)

      expected_binary = <<0x00, 0x10, 0x10, 0x00, 0x00>>

      assert expected_binary == ZIPPacket.encode_params(command)
    end

    test "when there is command" do
      {:ok, switch_set} = SwitchBinarySet.new(target_value: :on)
      {:ok, command} = ZIPPacket.with_zwave_command(switch_set, 0xA0)

      expected_binary = <<0x80, 0x50, 0xA0, 0x00, 0x00>> <> ZWave.to_binary(switch_set)

      assert expected_binary == ZIPPacket.encode_params(command)
    end
  end
end
