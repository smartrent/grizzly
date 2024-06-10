defmodule Grizzly.ZWave.Commands.ThermostatModeReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatModeReport

  test "creates the command and validates params" do
    params = [mode: :heat]
    {:ok, _command} = ThermostatModeReport.new(params)
  end

  test "encodes params correctly" do
    params = [mode: :fan]
    {:ok, command} = ThermostatModeReport.new(params)
    expected_binary = <<0x00::3, 0x06::5>>
    assert expected_binary == ThermostatModeReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::3, 0x03::5>>
    {:ok, params} = ThermostatModeReport.decode_params(binary_params)
    assert Keyword.get(params, :mode) == :auto
  end
end
