defmodule Grizzly.ZWave.Commands.ThermostatSetpointSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatSetpointSupportedReport

  test "creates the command and validates params" do
    params = [
      setpoint_types: [
        heating: true,
        cooling: true,
        furnace: true,
        dry_air: true,
        moist_air: true,
        auto_changeover: true,
        energy_save_heating: true,
        energy_save_cooling: true,
        away_heating: true,
        away_cooling: true,
        full_power: true
      ]
    ]

    {:ok, _command} = ThermostatSetpointSupportedReport.new(params)
  end

  test "encodes params correctly" do
    # all the odd bits
    params = [
      setpoint_types: [
        heating: true,
        cooling: false,
        furnace: true,
        dry_air: false,
        moist_air: true,
        auto_changeover: false,
        energy_save_heating: true,
        energy_save_cooling: false,
        away_heating: true,
        away_cooling: false,
        full_power: true
      ]
    ]

    {:ok, command} = ThermostatSetpointSupportedReport.new(params)

    ThermostatSetpointSupportedReport.encode_params(command)

    assert <<0b10101010, 0b00001010>> == ThermostatSetpointSupportedReport.encode_params(command)

    # all the even bits
    params = [
      setpoint_types: [
        heating: false,
        cooling: true,
        furnace: false,
        dry_air: true,
        moist_air: false,
        auto_changeover: true,
        energy_save_heating: false,
        energy_save_cooling: true,
        away_heating: false,
        away_cooling: true,
        full_power: false
      ]
    ]

    {:ok, command} = ThermostatSetpointSupportedReport.new(params)

    ThermostatSetpointSupportedReport.encode_params(command)

    assert <<0b01010100, 0b00000101>> == ThermostatSetpointSupportedReport.encode_params(command)

    # just heating
    params = [setpoint_types: [heating: true]]

    {:ok, command} = ThermostatSetpointSupportedReport.new(params)

    ThermostatSetpointSupportedReport.encode_params(command)

    assert <<0b10, 0b0>> == ThermostatSetpointSupportedReport.encode_params(command)
  end

  describe "decodes params correctly" do
    test "two bytes of bitmasks" do
      # odd bits are set in both bitmasks
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(<<0b10101010, 0b10101010>>)

      assert setpoint_types == [
               heating: true,
               cooling: false,
               furnace: true,
               dry_air: false,
               moist_air: true,
               auto_changeover: false,
               energy_save_heating: true,
               energy_save_cooling: false,
               away_heating: true,
               away_cooling: false,
               full_power: true
             ]

      # even bits are set in both bitmasks
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(<<0b01010101, 0b01010101>>)

      assert setpoint_types == [
               heating: false,
               cooling: true,
               furnace: false,
               dry_air: true,
               moist_air: false,
               auto_changeover: true,
               energy_save_heating: false,
               energy_save_cooling: true,
               away_heating: false,
               away_cooling: true,
               full_power: false
             ]

      # all bits are set
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(<<0xFF, 0xFF>>)

      assert setpoint_types == [
               heating: true,
               cooling: true,
               furnace: true,
               dry_air: true,
               moist_air: true,
               auto_changeover: true,
               energy_save_heating: true,
               energy_save_cooling: true,
               away_heating: true,
               away_cooling: true,
               full_power: true
             ]

      # no bits are set
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(<<0x0, 0x0>>)

      assert setpoint_types == [
               heating: false,
               cooling: false,
               furnace: false,
               dry_air: false,
               moist_air: false,
               auto_changeover: false,
               energy_save_heating: false,
               energy_save_cooling: false,
               away_heating: false,
               away_cooling: false,
               full_power: false
             ]
    end

    test "just one byte" do
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(<<0xFF>>)

      assert setpoint_types == [
               heating: true,
               cooling: true,
               furnace: true,
               dry_air: true,
               moist_air: true,
               auto_changeover: true,
               energy_save_heating: true,
               energy_save_cooling: false,
               away_heating: false,
               away_cooling: false,
               full_power: false
             ]
    end

    test "extra bytes" do
      # just one byte
      assert {:ok, setpoint_types: setpoint_types} =
               ThermostatSetpointSupportedReport.decode_params(<<0x00, 0x00, 0xFF>>)

      assert setpoint_types == [
               heating: false,
               cooling: false,
               furnace: false,
               dry_air: false,
               moist_air: false,
               auto_changeover: false,
               energy_save_heating: false,
               energy_save_cooling: false,
               away_heating: false,
               away_cooling: false,
               full_power: false
             ]
    end
  end
end
