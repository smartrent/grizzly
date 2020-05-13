defmodule Grizzly.ZWave.Commands.ThermostatFanModeReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatFanModeReport

  test "creates the command and validates params" do
    params = [mode: :auto_high]
    {:ok, _command} = ThermostatFanModeReport.new(params)
  end

  test "encodes params correctly" do
    params = [mode: :auto_high]
    {:ok, command} = ThermostatFanModeReport.new(params)
    expected_binary = <<0x00::size(4), 0x02::size(4)>>
    assert expected_binary == ThermostatFanModeReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::size(4), 0x03::size(4)>>
    {:ok, params} = ThermostatFanModeReport.decode_params(binary_params)
    assert Keyword.get(params, :mode) == :high
  end
end
