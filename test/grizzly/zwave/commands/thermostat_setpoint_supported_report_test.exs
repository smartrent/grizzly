defmodule Grizzly.ZWave.Commands.ThermostatSetpointSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ThermostatSetpointSupportedReport

  test "creates the command and validates params" do
    params = [
      setpoint_types: [
        :heating,
        :cooling,
        :furnace,
        :dry_air,
        :moist_air,
        :auto_changeover,
        :energy_save_heating,
        :energy_save_cooling,
        :away_heating,
        :away_cooling,
        :full_power
      ]
    ]

    {:ok, _command} = Commands.create(:thermostat_setpoint_supported_report, params)
  end

  test "encodes params correctly" do
    # all the odd bits
    params = [
      setpoint_types: [
        :heating,
        :furnace,
        :moist_air,
        :energy_save_heating,
        :away_heating,
        :full_power
      ]
    ]

    {:ok, command} = Commands.create(:thermostat_setpoint_supported_report, params)

    ThermostatSetpointSupportedReport.encode_params(nil, command)

    assert <<0b10101010, 0b00001010>> ==
             ThermostatSetpointSupportedReport.encode_params(nil, command)

    # all the even bits
    params = [
      setpoint_types: [
        :cooling,
        :dry_air,
        :auto_changeover,
        :energy_save_cooling,
        :away_cooling
      ]
    ]

    {:ok, command} = Commands.create(:thermostat_setpoint_supported_report, params)

    ThermostatSetpointSupportedReport.encode_params(nil, command)

    assert <<0b01010100, 0b00000101>> ==
             ThermostatSetpointSupportedReport.encode_params(nil, command)

    # just heating
    params = [setpoint_types: [:heating]]

    {:ok, command} = Commands.create(:thermostat_setpoint_supported_report, params)

    ThermostatSetpointSupportedReport.encode_params(nil, command)

    assert <<0b10, 0b0>> == ThermostatSetpointSupportedReport.encode_params(nil, command)
  end

  describe "decodes params correctly" do
    test "two bytes of bitmasks" do
      # odd bits are set in both bitmasks
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(nil, <<0b10101010, 0b10101010>>)

      assert setpoint_types == [
               :heating,
               :furnace,
               :moist_air,
               :energy_save_heating,
               :away_heating,
               :full_power
             ]

      # even bits are set in both bitmasks
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(nil, <<0b01010101, 0b01010101>>)

      assert setpoint_types == [
               :cooling,
               :dry_air,
               :auto_changeover,
               :energy_save_cooling,
               :away_cooling
             ]

      # all bits are set
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(nil, <<0xFF, 0xFF>>)

      assert setpoint_types == [
               :heating,
               :cooling,
               :furnace,
               :dry_air,
               :moist_air,
               :auto_changeover,
               :energy_save_heating,
               :energy_save_cooling,
               :away_heating,
               :away_cooling,
               :full_power
             ]

      # no bits are set
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(nil, <<0x0, 0x0>>)

      assert setpoint_types == []
    end

    test "just one byte" do
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(nil, <<0xFF>>)

      assert setpoint_types == [
               :heating,
               :cooling,
               :furnace,
               :dry_air,
               :moist_air,
               :auto_changeover,
               :energy_save_heating
             ]
    end

    test "extra bytes" do
      # just one byte
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(nil, <<0x00, 0x00, 0xFF>>)

      assert setpoint_types == []
    end
  end
end
