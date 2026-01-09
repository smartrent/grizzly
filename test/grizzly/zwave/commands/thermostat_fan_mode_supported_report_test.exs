defmodule Grizzly.ZWave.Commands.ThermostatFanModeSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatFanModeSupportedReport

  test "encodes params correctly" do
    modes = [:auto_low, :low, :auto_high, :auto_medium]

    {:ok, cmd} = Commands.create(:thermostat_fan_mode_supported_report, modes: modes)

    expected_binary = <<0b00010111>>

    assert expected_binary == ThermostatFanModeSupportedReport.encode_params(cmd)
  end

  test "decodes params correctly" do
    binary = <<0b00010111>>

    assert {:ok, [modes: [:auto_low, :low, :auto_high, :auto_medium]]} ==
             ThermostatFanModeSupportedReport.decode_params(binary)
  end
end
