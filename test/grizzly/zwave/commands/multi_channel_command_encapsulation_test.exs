defmodule Grizzly.ZWave.Commands.MultiChannelCommandEncapsulationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelCommandEncapsulation

  test "creates the command and validates params" do
    params = [
      source_end_point: 1,
      destination_end_point: 2,
      bit_address?: true,
      command_class: :switch_binary,
      command: :switch_binary_set,
      parameters: [target_value: :on, duration: 0]
    ]

    {:ok, _command} = Commands.create(:multi_channel_command_encapsulation, params)
  end

  test "encodes params correctly" do
    params = [
      source_end_point: 1,
      destination_end_point: 3,
      bit_address?: true,
      command_class: :switch_binary,
      command: :switch_binary_set,
      parameters: [target_value: :on, duration: 0]
    ]

    {:ok, command} = Commands.create(:multi_channel_command_encapsulation, params)

    expected_binary =
      <<0x00::1, 0x01::7, 0x01::1, 0x04::7, 0x25, 0x01, 0xFF, 0x00>>

    assert expected_binary == MultiChannelCommandEncapsulation.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary =
      <<0x00::1, 0x01::7, 0x01::1, 0x04::7, 0x25, 0x01, 0xFF, 0x00>>

    {:ok, params} = MultiChannelCommandEncapsulation.decode_params(params_binary)
    assert Keyword.get(params, :source_end_point) == 1
    assert Keyword.get(params, :destination_end_point) == 3
    assert Keyword.get(params, :bit_address?) == true
    assert Keyword.get(params, :command_class) == :switch_binary
    assert Keyword.get(params, :command) == :switch_binary_set

    assert Enum.sort(Keyword.get(params, :parameters)) ==
             Enum.sort(target_value: :on, duration: 0)
  end
end
