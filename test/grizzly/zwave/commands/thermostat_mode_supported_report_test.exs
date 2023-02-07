defmodule Grizzly.ZWave.Commands.ThermostatModeSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatModeSupportedReport

  test "creates the command and validates params" do
    {:ok, _command} = ThermostatModeSupportedReport.new(modes: [])

    modes = [
      off: true,
      heat: true,
      cool: true,
      auto: true,
      auxiliary: true,
      resume_on: true,
      fan: true,
      furnace: true,
      dry: true,
      moist: true,
      auto_changeover: true,
      energy_heat: true,
      energy_cool: true,
      away: true,
      full_power: true,
      manufacturer_specific: true
    ]

    {:ok, _command} = ThermostatModeSupportedReport.new(modes: modes)
  end

  test "encodes params correctly" do
    {:ok, command} = ThermostatModeSupportedReport.new(modes: [])
    assert <<>> = ThermostatModeSupportedReport.encode_params(command)

    modes = [
      off: true,
      heat: true,
      cool: true,
      auto: true,
      auxiliary: true,
      resume_on: false,
      fan: false,
      furnace: false,
      dry: false,
      moist: false,
      auto_changeover: false,
      energy_heat: true,
      energy_cool: true,
      away: false,
      full_power: false,
      manufacturer_specific: false
    ]

    {:ok, command} = ThermostatModeSupportedReport.new(modes: modes)
    assert <<0x1F, 0x18>> = ThermostatModeSupportedReport.encode_params(command)

    modes = [
      off: true,
      heat: true,
      cool: true,
      auto: true,
      auxiliary: true,
      resume_on: true,
      fan: true,
      furnace: true,
      dry: true,
      moist: true,
      auto_changeover: true,
      energy_heat: true,
      energy_cool: true,
      away: true,
      full_power: true,
      manufacturer_specific: true
    ]

    {:ok, command} = ThermostatModeSupportedReport.new(modes: modes)
    assert <<0xFF, 0xBF, 0x0, 0x80>> = ThermostatModeSupportedReport.encode_params(command)
  end

  test "decodes params correctly" do
    assert {:ok, [modes: modes]} = ThermostatModeSupportedReport.decode_params(<<0x1F, 0x18>>)

    assert modes[:off]
    assert modes[:heat]
    assert modes[:cool]
    assert modes[:auto]
    assert modes[:auxiliary]
    refute modes[:resume_on]
    refute modes[:fan]
    refute modes[:furnace]
    refute modes[:dry]
    refute modes[:moist]
    refute modes[:auto_changeover]
    assert modes[:energy_heat]
    assert modes[:energy_cool]
    refute modes[:away]
    refute modes[:full_power]
    refute modes[:manufacturer_specific]
  end
end
