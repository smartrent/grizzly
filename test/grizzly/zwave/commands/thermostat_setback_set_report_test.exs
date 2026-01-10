defmodule Grizzly.ZWave.Commands.ThermostatSetbackSetReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatSetbackSetReport

  test "creates the command and validates params" do
    params = [type: :no_override, state: :frost_protection]
    {:ok, _command} = Commands.create(:thermostat_setback_set, params)
  end

  test "encodes params correctly" do
    params = [type: :temporary_override, state: -12.7]
    {:ok, command} = Commands.create(:thermostat_setback_set, params)
    expected_binary = <<0x00::6, 0x01::2, 0x81>>
    assert expected_binary == ThermostatSetbackSetReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::6, 0x02::2, 0x7A>>
    {:ok, params} = ThermostatSetbackSetReport.decode_params(binary_params)
    assert Keyword.get(params, :type) == :permanent_override
    assert Keyword.get(params, :state) == :energy_saving
  end
end
