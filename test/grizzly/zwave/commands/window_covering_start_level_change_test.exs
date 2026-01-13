defmodule Grizzly.ZWave.Commands.WindowCoveringStartLevelChangeTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.WindowCoveringStartLevelChange

  test "creates the command and validates params" do
    params = [parameter_name: :out_left_positioned, direction: :down, duration: 5]
    {:ok, _command} = Commands.create(:window_covering_start_level_change, params)
  end

  test "encodes params correctly" do
    params = [parameter_name: :out_left_positioned, direction: :down, duration: 5]
    {:ok, command} = Commands.create(:window_covering_start_level_change, params)
    expected_binary = <<0x00::1, 0x01::1, 0x00::6, 1, 5>>
    assert expected_binary == WindowCoveringStartLevelChange.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::1, 0x01::1, 0x00::6, 1, 5>>
    {:ok, params} = WindowCoveringStartLevelChange.decode_params(nil, binary_params)
    assert Keyword.get(params, :parameter_name) == :out_left_positioned
    assert Keyword.get(params, :direction) == :down
    assert Keyword.get(params, :duration) == 5
  end
end
