defmodule Grizzly.ZWave.Commands.ThermostatSetpointReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatSetpointReport

  test "creates the command and validates params" do
    params = [type: :heating, scale: :f, value: 75.5]
    {:ok, _command} = Commands.create(:thermostat_setpoint_report, params)
  end

  test "encodes params correctly" do
    params = [type: :heating, scale: :f, value: 75.5]
    {:ok, command} = Commands.create(:thermostat_setpoint_report, params)

    expected_binary =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x02::3, 0x02, 0xF3>>

    assert expected_binary == ThermostatSetpointReport.encode_params(nil, command)

    params = [type: :heating, scale: :f, value: -75.5]
    {:ok, command} = Commands.create(:thermostat_setpoint_report, params)

    expected_binary =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x02::3, 0xFD, 0x0D>>

    assert expected_binary == ThermostatSetpointReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x02::3, 0x02, 0xF3>>

    {:ok, params} = ThermostatSetpointReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :type) == :heating
    assert Keyword.get(params, :scale) == :f
    assert Keyword.get(params, :value) == 75.5

    binary_params =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x02::3, 0xFD, 0x0D>>

    {:ok, params} = ThermostatSetpointReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :type) == :heating
    assert Keyword.get(params, :scale) == :f
    assert Keyword.get(params, :value) == -75.5
  end

  test "decodes params correctly when there is a trailing junk byte (Aidoo Airzone)" do
    binary_params =
      <<0x00::4, 0x01::4, 0x01::3, 0x01::2, 0x02::3, 0x02, 0xF3, 0x00>>

    {:ok, params} = ThermostatSetpointReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :type) == :heating
    assert Keyword.get(params, :scale) == :f
    assert Keyword.get(params, :value) == 75.5
  end

  test "encodes :na type" do
    {:ok, command} =
      Commands.create(
        :thermostat_setpoint_report,
        type: :na,
        value: 70,
        scale: :f
      )

    expected_bin = <<0x00::4, 0x00::4, 0x00::3, 0x01::2, 0x01::3, 0x00>>

    assert ThermostatSetpointReport.encode_params(nil, command) == expected_bin
  end

  test "parses :na type" do
    binary = <<0x00::4, 0x00::4, 0x01::3, 0x01::2, 0x02::3, 0x00, 0x00>>

    expected_params = [
      type: :na,
      value: 0
    ]

    {:ok, params} = ThermostatSetpointReport.decode_params(nil, binary)

    for {param, value} <- expected_params do
      assert params[param] == value
    end
  end
end
