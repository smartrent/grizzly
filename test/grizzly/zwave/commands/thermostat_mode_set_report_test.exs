defmodule Grizzly.ZWave.Commands.ThermostatModeSetReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatModeSetReport

  test "creates the command and validates params" do
    params = [mode: :heat]
    {:ok, _command} = Commands.create(:thermostat_mode_set, params)
  end

  test "encodes params correctly" do
    params = [mode: :heat]
    {:ok, command} = Commands.create(:thermostat_mode_set, params)
    expected_binary = <<0x00::3, 0x01::5>>
    assert expected_binary == ThermostatModeSetReport.encode_params(nil, command)

    assert_raise KeyError, fn ->
      params = [mode: :manufacturer_specific]
      {:ok, cmd} = Commands.create(:thermostat_mode_set, params)
      ThermostatModeSetReport.encode_params(nil, cmd)
    end

    assert_raise ArgumentError, fn ->
      params = [mode: :manufacturer_specific, manufacturer_data: "12345678"]
      {:ok, cmd} = Commands.create(:thermostat_mode_set, params)
      ThermostatModeSetReport.encode_params(nil, cmd)
    end

    params = [mode: :manufacturer_specific, manufacturer_data: "1234567"]
    {:ok, cmd} = Commands.create(:thermostat_mode_set, params)
    assert <<0xFF, "1234567">> = ThermostatModeSetReport.encode_params(nil, cmd)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::3, 0x02::5>>
    {:ok, params} = ThermostatModeSetReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :mode) == :cool

    assert {:ok, params} = ThermostatModeSetReport.decode_params(nil, <<0xFF, "1234567">>)
    assert params == [mode: :manufacturer_specific, manufacturer_data: "1234567"]
  end
end
