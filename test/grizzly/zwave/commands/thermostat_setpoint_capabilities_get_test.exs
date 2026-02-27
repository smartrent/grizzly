defmodule Grizzly.ZWave.Commands.ThermostatSetpointCapabilitiesGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  test "encodes params correctly" do
    params = [
      type: :heating
    ]

    {:ok, cmd} = Commands.create(:thermostat_setpoint_capabilities_get, params)

    expected_binary = <<0x43, 0x09, 0::4, 1::4>>
    assert expected_binary == Grizzly.encode_command(cmd)
  end

  test "decodes params correctly" do
    binary = <<0x43, 0x09, 0::4, 1::4>>

    {:ok, cmd} = Grizzly.decode_command(binary)
    assert cmd.params[:type] == :heating
  end
end
