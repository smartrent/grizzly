defmodule Grizzly.CommandClass.ThermostatMode.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.ThermostatMode

  describe "mode to byte" do
    test "off" do
      assert {:ok, 0x00} == ThermostatMode.encode_mode(:off)
    end

    test "heat" do
      assert {:ok, 0x01} == ThermostatMode.encode_mode(:heat)
    end

    test "cool" do
      assert {:ok, 0x02} == ThermostatMode.encode_mode(:cool)
    end

    test "auto" do
      assert {:ok, 0x03} == ThermostatMode.encode_mode(:auto)
    end
  end

  describe "mode from byte" do
    test "off" do
      assert :off == ThermostatMode.decode_mode(0x00)
    end

    test "heat" do
      assert :heat == ThermostatMode.decode_mode(0x01)
    end

    test "cool" do
      assert :cool == ThermostatMode.decode_mode(0x02)
    end

    test "auto" do
      assert :auto == ThermostatMode.decode_mode(0x03)
    end
  end
end
