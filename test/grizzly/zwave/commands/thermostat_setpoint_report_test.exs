defmodule Grizzly.ZWave.Commands.ThermostatSetpointReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatSetpointReport

  test "creates the command and validates params" do
    params = [type: :heating, scale: :fahrenheit, value: 75.5]
    {:ok, _command} = ThermostatSetpointReport.new(params)
  end

  test "encodes params correctly" do
    params = [type: :heating, scale: :fahrenheit, value: 75.5]
    {:ok, command} = ThermostatSetpointReport.new(params)

    expected_binary =
      <<0x00::size(4), 0x01::size(4), 0x01::size(3), 0x01::size(2), 0x02::size(3), 0x02, 0xF3>>

    assert expected_binary == ThermostatSetpointReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x00::size(4), 0x01::size(4), 0x01::size(3), 0x01::size(2), 0x02::size(3), 0x02, 0xF3>>

    {:ok, params} = ThermostatSetpointReport.decode_params(binary_params)
    assert Keyword.get(params, :type) == :heating
    assert Keyword.get(params, :scale) == :fahrenheit
    assert Keyword.get(params, :value) == 75.5
  end
end
