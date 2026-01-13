defmodule Grizzly.ZWave.Commands.CRC16EncapTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CRC16Encap
  alias Grizzly.ZWave.Commands.SwitchMultilevelSet
  alias Grizzly.ZWave.CRC

  test "creates the command and validates params" do
    {:ok, encap_command} = Commands.create(:switch_multilevel_set, target_value: :off)
    params = [command: encap_command]
    {:ok, _command} = Commands.create(:crc_16_encap, params)
  end

  test "encodes params correctly" do
    {:ok, encap_command} = Commands.create(:switch_multilevel_set, target_value: :off)
    params = [command: encap_command]
    {:ok, command} = Commands.create(:crc_16_encap, params)
    encoded_encap_params = SwitchMultilevelSet.encode_params(nil, encap_command)
    command_binary = <<0x26, 0x01>> <> encoded_encap_params
    checksum = CRC.crc16_aug_ccitt(command_binary)
    expected_binary = command_binary <> <<checksum::16>>
    assert expected_binary == CRC16Encap.encode_params(nil, command)
  end

  test "decodes params correctly" do
    {:ok, encap_command} = Commands.create(:switch_multilevel_set, target_value: :off)
    encoded_encap_params = SwitchMultilevelSet.encode_params(nil, encap_command)
    command_binary = <<0x26, 0x01>> <> encoded_encap_params
    checksum = CRC.crc16_aug_ccitt(command_binary)
    params_binary = command_binary <> <<checksum::16>>
    {:ok, params} = CRC16Encap.decode_params(nil, params_binary)
    encap_command = Keyword.get(params, :command)
    assert encap_command.command_byte == 0x01
    encap_params = encap_command.params
    assert Keyword.get(encap_params, :target_value) == :off
  end
end
