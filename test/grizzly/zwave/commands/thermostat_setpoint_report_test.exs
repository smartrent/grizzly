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

  test "encodes :na type" do
    {:ok, command} =
      ThermostatSetpointReport.new(
        type: :na,
        value: 70,
        scale: :fahrenheit
      )

    expected_bin = <<0x00::4, 0x00::4, 0x00::3, 0x01::2, 0x01::3, 0x00>>

    assert ThermostatSetpointReport.encode_params(command) == expected_bin
  end

  test "parses :na type" do
    binary = <<0x00::4, 0x00::4, 0x01::3, 0x01::2, 0x02::3, 0x00, 0x00>>

    expected_params = [
      type: :na,
      value: 0
    ]

    {:ok, params} = ThermostatSetpointReport.decode_params(binary)

    for {param, value} <- expected_params do
      assert params[param] == value
    end
  end
end
