defmodule Grizzly.ZWave.Commands.CRC16EncapTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.{CRC16Encap, SwitchMultilevelSet}
  alias Grizzly.ZWave.CRC

  test "creates the command and validates params" do
    {:ok, encap_command} = SwitchMultilevelSet.new(target_value: :off)
    params = [command: encap_command]
    {:ok, _command} = CRC16Encap.new(params)
  end

  test "encodes params correctly" do
    {:ok, encap_command} = SwitchMultilevelSet.new(target_value: :off)
    params = [command: encap_command]
    {:ok, command} = CRC16Encap.new(params)
    encoded_encap_params = SwitchMultilevelSet.encode_params(encap_command)
    command_binary = <<0x26, 0x01>> <> encoded_encap_params
    checksum = CRC.crc16_aug_ccitt(command_binary)
    expected_binary = command_binary <> <<checksum::size(2)-integer-unsigned-unit(8)>>
    assert expected_binary == CRC16Encap.encode_params(command)
  end

  test "decodes params correctly" do
    {:ok, encap_command} = SwitchMultilevelSet.new(target_value: :off)
    encoded_encap_params = SwitchMultilevelSet.encode_params(encap_command)
    command_binary = <<0x26, 0x01>> <> encoded_encap_params
    checksum = CRC.crc16_aug_ccitt(command_binary)
    params_binary = command_binary <> <<checksum::size(2)-integer-unsigned-unit(8)>>
    {:ok, params} = CRC16Encap.decode_params(params_binary)
    encap_command = Keyword.get(params, :command)
    assert encap_command.command_byte == 0x01
    encap_command_class_byte = apply(encap_command.command_class, :byte, [])
    assert encap_command_class_byte == 0x26
    encap_params = encap_command.params
    assert Keyword.get(encap_params, :target_value) == :off
  end
end
