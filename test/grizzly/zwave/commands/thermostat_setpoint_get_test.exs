defmodule Grizzly.ZWave.Commands.ThermostatSetpointGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatSetpointGet

  test "creates the command and validates params" do
    params = [type: :heating]
    {:ok, _command} = ThermostatSetpointGet.new(params)
  end

  test "encodes params correctly" do
    params = [type: :heating]
    {:ok, command} = ThermostatSetpointGet.new(params)

    expected_binary = <<0x00::4, 0x01::4>>

    assert expected_binary == ThermostatSetpointGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::4, 0x01::4>>

    {:ok, params} = ThermostatSetpointGet.decode_params(binary_params)
    assert Keyword.get(params, :type) == :heating
  end
end
