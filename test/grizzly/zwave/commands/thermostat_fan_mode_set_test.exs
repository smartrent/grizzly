defmodule Grizzly.ZWave.Commands.ThermostatFanModeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatFanModeSet

  test "creates the command and validates params" do
    params = [mode: :auto_high]
    {:ok, _command} = ThermostatFanModeSet.new(params)
  end

  test "encodes params correctly" do
    params = [mode: :auto_high]
    {:ok, command} = ThermostatFanModeSet.new(params)
    expected_binary = <<0x00::4, 0x02::4>>
    assert expected_binary == ThermostatFanModeSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::4, 0x03::4>>
    {:ok, params} = ThermostatFanModeSet.decode_params(binary_params)
    assert Keyword.get(params, :mode) == :high
  end
end
