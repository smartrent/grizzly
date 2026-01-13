defmodule Grizzly.ZWave.Commands.ThermostatFanStateReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatFanStateReport

  test "creates the command and validates params" do
    params = [state: :running]
    {:ok, _command} = Commands.create(:thermostat_fan_state_report, params)
  end

  test "encodes params correctly" do
    params = [state: :running]
    {:ok, command} = Commands.create(:thermostat_fan_state_report, params)
    expected_binary = <<0x00::4, 0x01::4>>
    assert expected_binary == ThermostatFanStateReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::4, 0x02::4>>
    {:ok, params} = ThermostatFanStateReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :state) == :running_high
  end
end
