defmodule Grizzly.ZWave.Commands.ThermostatFanModeReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatFanModeReport

  test "creates the command and validates params" do
    params = [mode: :auto_high]
    {:ok, _command} = Commands.create(:thermostat_fan_mode_report, params)
  end

  test "encodes params correctly" do
    params = [mode: :auto_high]
    {:ok, command} = Commands.create(:thermostat_fan_mode_report, params)
    expected_binary = <<0x00::4, 0x02::4>>
    assert expected_binary == ThermostatFanModeReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::4, 0x03::4>>
    {:ok, params} = ThermostatFanModeReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :mode) == :high
  end
end
