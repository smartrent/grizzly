defmodule Grizzly.ZWave.Commands.ThermostatSetbackReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatSetbackReport

  test "creates the command and validates params" do
    params = [type: :no_override, state: :frost_protection]
    {:ok, _command} = ThermostatSetbackReport.new(params)
  end

  test "encodes params correctly" do
    params = [type: :temporary_override, state: -12.7]
    {:ok, command} = ThermostatSetbackReport.new(params)
    expected_binary = <<0x00::size(6), 0x01::size(2), 0x81>>
    assert expected_binary == ThermostatSetbackReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::size(6), 0x02::size(2), 0x7A>>
    {:ok, params} = ThermostatSetbackReport.decode_params(binary_params)
    assert Keyword.get(params, :type) == :permanent_override
    assert Keyword.get(params, :state) == :energy_saving
  end
end
