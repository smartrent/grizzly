defmodule Grizzly.ZWave.Commands.ThermostatSetpointCapabilitiesGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatSetpointCapabilitiesGet

  test "encodes params correctly" do
    params = [
      type: :heating
    ]

    {:ok, cmd} = ThermostatSetpointCapabilitiesGet.new(params)

    expected_binary = <<0::4, 1::4>>
    assert expected_binary == ThermostatSetpointCapabilitiesGet.encode_params(cmd)
  end

  test "decodes params correctly" do
    binary = <<0::4, 1::4>>

    {:ok, [type: :heating]} = ThermostatSetpointCapabilitiesGet.decode_params(binary)
  end
end
