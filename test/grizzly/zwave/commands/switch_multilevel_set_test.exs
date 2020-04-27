defmodule Grizzly.ZWave.Commands.SwitchMultilevelSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SwitchMultilevelSet

  test "creates the command and validates params" do
    params = [target_value: :off]
    {:ok, _command} = SwitchMultilevelSet.new(params)
  end

  test "encodes v1 params correctly" do
    params = [target_value: 99]
    {:ok, command} = SwitchMultilevelSet.new(params)
    expected_binary = <<0x63>>
    assert expected_binary == SwitchMultilevelSet.encode_params(command)
  end

  test "encodes v2 params correctly" do
    params = [target_value: 99, duration: 10]
    {:ok, command} = SwitchMultilevelSet.new(params)
    expected_binary = <<0x63, 0x0A>>
    assert expected_binary == SwitchMultilevelSet.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0xFF>>
    {:ok, params} = SwitchMultilevelSet.decode_params(binary_params)
    assert Keyword.get(params, :target_value) == :previous
  end

  test "decodes v2 params correctly" do
    binary_params = <<0x32, 0x0A>>
    {:ok, params} = SwitchMultilevelSet.decode_params(binary_params)
    assert Keyword.get(params, :target_value) == 0x32
    assert Keyword.get(params, :duration) == 0x0A
  end
end
