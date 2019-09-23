defmodule Grizzly.CommandClass.ThermostatFanMode.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.ThermostatFanMode

  describe "encode thermostat fan mod" do
    test "auto_low" do
      assert {:ok, 0x00} == ThermostatFanMode.encode_thermostat_fan_mode(:auto_low)
    end

    test "low" do
      assert {:ok, 0x01} == ThermostatFanMode.encode_thermostat_fan_mode(:low)
    end

    test "auto high" do
      assert {:ok, 0x02} == ThermostatFanMode.encode_thermostat_fan_mode(:auto_high)
    end

    test "high" do
      assert {:ok, 0x03} == ThermostatFanMode.encode_thermostat_fan_mode(:high)
    end
  end

  describe "decode thermostat fan mode" do
    test "auto low" do
      assert :auto_low == ThermostatFanMode.decode_thermostat_fan_mode(0x00)
    end

    test "low" do
      assert :low == ThermostatFanMode.decode_thermostat_fan_mode(0x01)
    end

    test "auto high" do
      assert :auto_high == ThermostatFanMode.decode_thermostat_fan_mode(0x02)
    end

    test "high" do
      assert :high == ThermostatFanMode.decode_thermostat_fan_mode(0x03)
    end
  end
end
