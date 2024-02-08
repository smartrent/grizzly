defmodule Grizzly.ZWave.Commands.ThermostatSetpointCapabilitiesReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatSetpointCapabilitiesReport

  test "encodes params correctly" do
    params = [
      type: :heating,
      min_scale: :c,
      min_value: 10.5,
      max_scale: :c,
      max_value: 30
    ]

    {:ok, cmd} = ThermostatSetpointCapabilitiesReport.new(params)

    expected_binary = <<0::4, 1::4, 1::3, 0::2, 1::3, 105, 0::3, 0::2, 1::3, 30>>
    assert expected_binary == ThermostatSetpointCapabilitiesReport.encode_params(cmd)
  end

  test "decodes params correctly" do
    binary = <<0::4, 1::4, 1::3, 0::2, 1::3, 105, 0::3, 0::2, 1::3, 30>>

    {:ok, [type: :heating, min_scale: :c, min_value: 10.5, max_scale: :c, max_value: 30]} =
      ThermostatSetpointCapabilitiesReport.decode_params(binary)
  end
end
