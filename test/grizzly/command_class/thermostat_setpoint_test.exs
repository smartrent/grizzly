defmodule Grizzly.CommandClass.ThermostatSetpoint.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.ThermostatSetpoint

  test "encode cooling setpoint type" do
    assert 0x02 == ThermostatSetpoint.encode_setpoint_type(:cooling)
  end

  test "encode heating setpoint type" do
    assert 0x01 == ThermostatSetpoint.encode_setpoint_type(:heating)
  end

  test "decode cooling setpoint type" do
    assert :cooling == ThermostatSetpoint.decode_setpoint_type(0x02)
  end

  test "decode heating setpoint type" do
    assert :heating == ThermostatSetpoint.decode_setpoint_type(0x01)
  end
end
