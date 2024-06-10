defmodule Grizzly.ZWave.Commands.SwitchMultilevelStartLevelChangeTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SwitchMultilevelStartLevelChange

  test "creates the command and validates params" do
    params = [up_down: :up]
    {:ok, _command} = SwitchMultilevelStartLevelChange.new(params)
  end

  test "encodes v1 params correctly" do
    params = [up_down: :up]
    {:ok, command} = SwitchMultilevelStartLevelChange.new(params)
    expected_binary = <<0x00::1, 0x00::1, 0x01::1, 0x00::5, 0x00>>
    assert expected_binary == SwitchMultilevelStartLevelChange.encode_params(command)
  end

  test "encodes v2 params correctly" do
    params = [up_down: :down, duration: 10]
    {:ok, command} = SwitchMultilevelStartLevelChange.new(params)
    expected_binary = <<0x00::1, 0x01::1, 0x01::1, 0x00::5, 0x00, 0x0A>>
    assert expected_binary == SwitchMultilevelStartLevelChange.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<
      # Reserved
      0::1,
      # up/down
      0::1,
      # A controlling device SHOULD set the Ignore Start Level bit to 1.
      0x01::1,
      # Reserved
      0::5,
      # Start level is ignored
      0
    >>

    {:ok, params} = SwitchMultilevelStartLevelChange.decode_params(binary_params)
    assert Keyword.get(params, :up_down) == :up
  end

  test "decodes v2 params correctly" do
    binary_params = <<
      # Reserved
      0::1,
      # up/down
      1::1,
      # A controlling device SHOULD set the Ignore Start Level bit to 1.
      0x01::1,
      # Reserved
      0::5,
      # Start level is ignored
      0,
      # duration
      0x0B
    >>

    {:ok, params} = SwitchMultilevelStartLevelChange.decode_params(binary_params)
    assert Keyword.get(params, :up_down) == :down
    assert Keyword.get(params, :duration) == 11
  end
end
