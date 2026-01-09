defmodule Grizzly.ZWave.Commands.ThermostatModeSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatModeSupportedReport

  test "creates the command and validates params" do
    {:ok, _command} = Commands.create(:thermostat_mode_supported_report, modes: [])

    modes = [
      :off,
      :heat,
      :cool,
      :auto,
      :auxiliary,
      :resume_on,
      :fan,
      :furnace,
      :dry,
      :moist,
      :auto_changeover,
      :energy_heat,
      :energy_cool,
      :away,
      :full_power,
      :manufacturer_specific
    ]

    {:ok, _command} = Commands.create(:thermostat_mode_supported_report, modes: modes)
  end

  test "encodes params correctly" do
    {:ok, command} = Commands.create(:thermostat_mode_supported_report, modes: [])
    assert <<>> = ThermostatModeSupportedReport.encode_params(command)

    modes = [
      :off,
      :heat,
      :cool,
      :auto,
      :auxiliary,
      :energy_heat,
      :energy_cool
    ]

    {:ok, command} = Commands.create(:thermostat_mode_supported_report, modes: modes)
    assert <<0x1F, 0x18>> = ThermostatModeSupportedReport.encode_params(command)

    modes = [
      :off,
      :heat,
      :cool,
      :auto,
      :auxiliary,
      :resume_on,
      :fan,
      :furnace,
      :dry,
      :moist,
      :auto_changeover,
      :energy_heat,
      :energy_cool,
      :away,
      :full_power,
      :manufacturer_specific
    ]

    {:ok, command} = Commands.create(:thermostat_mode_supported_report, modes: modes)
    assert <<0xFF, 0xBF, 0x0, 0x80>> = ThermostatModeSupportedReport.encode_params(command)
  end

  test "decodes params correctly" do
    assert {:ok, [modes: modes]} = ThermostatModeSupportedReport.decode_params(<<0x1F, 0x18>>)

    assert :off in modes
    assert :heat in modes
    assert :cool in modes
    assert :auto in modes
    assert :auxiliary in modes
    refute :resume_on in modes
    refute :fan in modes
    refute :furnace in modes
    refute :dry in modes
    refute :moist in modes
    refute :auto_changeover in modes
    assert :energy_heat in modes
    assert :energy_cool in modes
    refute :away in modes
    refute :full_power in modes
    refute :manufacturer_specific in modes
  end
end
