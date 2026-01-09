defmodule Grizzly.ZWave.Commands.ThermostatSetpointSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatSetpointSet

  test "creates the command and validates params" do
    params = [type: :heating, scale: :c, value: 75.5]
    {:ok, _command} = Commands.create(:thermostat_setpoint_set, params)
  end

  test "encodes params correctly" do
    params = [type: :heating, scale: :f, value: 75.5]
    {:ok, command} = Commands.create(:thermostat_setpoint_set, params)

    expected_binary =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x02::3, 0x02, 0xF3>>

    assert expected_binary == ThermostatSetpointSet.encode_params(command)

    params = [type: :heating, scale: :f, value: -2.5]
    {:ok, command} = Commands.create(:thermostat_setpoint_set, params)

    expected_binary =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x01::3, 0xE7>>

    assert expected_binary == ThermostatSetpointSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x02::3, 0x02, 0xF3>>

    {:ok, params} = ThermostatSetpointSet.decode_params(binary_params)
    assert Keyword.get(params, :type) == :heating
    assert Keyword.get(params, :scale) == :f
    assert Keyword.get(params, :value) == 75.5

    binary_params =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x01::3, 0xE7>>

    {:ok, params} = ThermostatSetpointSet.decode_params(binary_params)
    assert Keyword.get(params, :type) == :heating
    assert Keyword.get(params, :scale) == :f
    assert Keyword.get(params, :value) == -2.5
  end
end
