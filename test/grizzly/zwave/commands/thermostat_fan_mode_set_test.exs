defmodule Grizzly.ZWave.Commands.ThermostatFanModeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatFanModeSet

  test "creates the command and validates params" do
    params = [mode: :auto_high]
    {:ok, _command} = Commands.create(:thermostat_fan_mode_set, params)
  end

  test "encodes params correctly" do
    params = [mode: :auto_high]
    {:ok, command} = Commands.create(:thermostat_fan_mode_set, params)
    expected_binary = <<0x00::4, 0x02::4>>
    assert expected_binary == ThermostatFanModeSet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::4, 0x03::4>>
    {:ok, params} = ThermostatFanModeSet.decode_params(nil, binary_params)
    assert Keyword.get(params, :mode) == :high
  end
end
