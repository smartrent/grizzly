defmodule Grizzly.CommandClass.ThermostatMode.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.ThermostatMode

  describe "mode to byte" do
    test "off" do
      assert 0x00 == ThermostatMode.mode_to_byte(:off)
    end

    test "heat" do
      assert 0x01 == ThermostatMode.mode_to_byte(:heat)
    end

    test "cool" do
      assert 0x02 == ThermostatMode.mode_to_byte(:cool)
    end

    test "auto" do
      assert 0x03 == ThermostatMode.mode_to_byte(:auto)
    end
  end

  describe "mode from byte" do
    test "off" do
      assert :off == ThermostatMode.mode_from_byte(0x00)
    end

    test "heat" do
      assert :heat == ThermostatMode.mode_from_byte(0x01)
    end

    test "cool" do
      assert :cool == ThermostatMode.mode_from_byte(0x02)
    end

    test "auto" do
      assert :auto == ThermostatMode.mode_from_byte(0x03)
    end
  end
end
