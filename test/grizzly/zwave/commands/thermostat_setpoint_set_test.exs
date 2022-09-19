defmodule Grizzly.ZWave.Commands.ThermostatSetpointSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatSetpointSet

  test "creates the command and validates params" do
    params = [type: :heating, scale: :celsius, value: 75.5]
    {:ok, _command} = ThermostatSetpointSet.new(params)
  end

  test "encodes params correctly" do
    params = [type: :heating, scale: :fahrenheit, value: 75.5]
    {:ok, command} = ThermostatSetpointSet.new(params)

    expected_binary =
      <<0x00::size(4), 0x01::size(4), 0x01::size(3), 0x01::size(2), 0x02::size(3), 0x02, 0xF3>>

    assert expected_binary == ThermostatSetpointSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x00::size(4), 0x01::size(4), 0x01::size(3), 0x01::size(2), 0x02::size(3), 0x02, 0xF3>>

    {:ok, params} = ThermostatSetpointSet.decode_params(binary_params)
    assert Keyword.get(params, :type) == :heating
    assert Keyword.get(params, :scale) == :fahrenheit
    assert Keyword.get(params, :value) == 75.5
  end
end
