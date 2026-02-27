defmodule Grizzly.ZWave.Commands.WindowCoveringStopLevelChangeTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  test "encodes params correctly" do
    params = [parameter_name: :out_left_positioned]
    {:ok, command} = Commands.create(:window_covering_stop_level_change, params)
    expected_binary = <<0x6A, 0x07, 1>>
    assert expected_binary == Grizzly.encode_command(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x6A, 0x07, 1>>
    {:ok, cmd} = Grizzly.decode_command(binary_params)
    assert Keyword.get(cmd.params, :parameter_name) == :out_left_positioned
  end
end
