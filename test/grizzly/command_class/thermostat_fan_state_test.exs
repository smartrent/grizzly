defmodule Grizzly.CommandClass.ThermostatFanState.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.ThermostatFanState

  describe "decoding thermostat fan state" do
    test "off" do
      assert :off == ThermostatFanState.decode_state(0)
    end

    test "running" do
      assert :running == ThermostatFanState.decode_state(1)
    end

    test "running high" do
      assert :running_high == ThermostatFanState.decode_state(2)
    end

    test "running medium" do
      assert :running_medium == ThermostatFanState.decode_state(3)
    end

    test "circulation_mode" do
      assert :circulation_mode == ThermostatFanState.decode_state(4)
    end

    test "humidity_circulation_mode" do
      assert :humidity_circulation_mode == ThermostatFanState.decode_state(5)
    end

    test "right_left_circulation_mode" do
      assert :right_left_circulation_mode == ThermostatFanState.decode_state(6)
    end

    test "up_down_circulation_mode" do
      assert :up_down_circulation_mode == ThermostatFanState.decode_state(7)
    end

    test "quite_circulation_mode" do
      assert :quite_circulation_mode == ThermostatFanState.decode_state(8)
    end
  end
end
