defmodule Grizzly.ZWave.Commands.ThermostatModeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatModeSet

  test "creates the command and validates params" do
    params = [mode: :heat]
    {:ok, _command} = ThermostatModeSet.new(params)
  end

  test "encodes params correctly" do
    params = [mode: :heat]
    {:ok, command} = ThermostatModeSet.new(params)
    expected_binary = <<0x00::3, 0x01::5>>
    assert expected_binary == ThermostatModeSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::3, 0x02::5>>
    {:ok, params} = ThermostatModeSet.decode_params(binary_params)
    assert Keyword.get(params, :mode) == :cool
  end
end
