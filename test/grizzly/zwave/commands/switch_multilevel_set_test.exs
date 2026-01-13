defmodule Grizzly.ZWave.Commands.SwitchMultilevelSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SwitchMultilevelSet

  test "creates the command and validates params" do
    params = [target_value: :off]
    {:ok, _command} = Commands.create(:switch_multilevel_set, params)
  end

  test "encodes v1 params correctly" do
    params = [target_value: 99]
    {:ok, command} = Commands.create(:switch_multilevel_set, params)
    expected_binary = <<0x63>>
    assert expected_binary == SwitchMultilevelSet.encode_params(nil, command)
  end

  test "encodes v2 params correctly" do
    params = [target_value: 99, duration: 10]
    {:ok, command} = Commands.create(:switch_multilevel_set, params)
    expected_binary = <<0x63, 0x0A>>
    assert expected_binary == SwitchMultilevelSet.encode_params(nil, command)

    params = [target_value: 99, duration: :default]
    {:ok, command} = Commands.create(:switch_multilevel_set, params)
    expected_binary = <<0x63, 0xFF>>
    assert expected_binary == SwitchMultilevelSet.encode_params(nil, command)

    params = [target_value: 99, duration: 180]
    {:ok, command} = Commands.create(:switch_multilevel_set, params)
    expected_binary = <<0x63, 0x82>>
    assert expected_binary == SwitchMultilevelSet.encode_params(nil, command)
  end

  test "encodes v2 params correctly - accept level 100" do
    params = [target_value: 100, duration: 10]
    {:ok, command} = Commands.create(:switch_multilevel_set, params)
    expected_binary = <<0x63, 0x0A>>
    assert expected_binary == SwitchMultilevelSet.encode_params(nil, command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0xFF>>
    {:ok, params} = SwitchMultilevelSet.decode_params(nil, binary_params)
    assert Keyword.get(params, :target_value) == :previous
  end

  test "decodes v2 params correctly" do
    binary_params = <<0x32, 0x0A>>
    {:ok, params} = SwitchMultilevelSet.decode_params(nil, binary_params)
    assert Keyword.get(params, :target_value) == 0x32
    assert Keyword.get(params, :duration) == 0x0A

    binary_params = <<0x32, 0xFF>>
    {:ok, params} = SwitchMultilevelSet.decode_params(nil, binary_params)
    assert Keyword.get(params, :target_value) == 0x32
    assert Keyword.get(params, :duration) == :default

    binary_params = <<0x32, 0x81>>
    {:ok, params} = SwitchMultilevelSet.decode_params(nil, binary_params)
    assert Keyword.get(params, :target_value) == 0x32
    assert Keyword.get(params, :duration) == 120
  end
end
