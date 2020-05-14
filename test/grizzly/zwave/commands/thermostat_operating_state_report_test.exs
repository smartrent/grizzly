defmodule Grizzly.ZWave.Commands.ThermostatOperatingStateReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatOperatingStateReport

  test "creates the command and validates params" do
    params = [state: :heating]
    {:ok, _command} = ThermostatOperatingStateReport.new(params)
  end

  test "encodes params correctly" do
    params = [state: :heating]
    {:ok, command} = ThermostatOperatingStateReport.new(params)
    expected_binary = <<0x01>>
    assert expected_binary == ThermostatOperatingStateReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02>>
    {:ok, params} = ThermostatOperatingStateReport.decode_params(binary_params)
    assert Keyword.get(params, :state) == :cooling
  end
end
