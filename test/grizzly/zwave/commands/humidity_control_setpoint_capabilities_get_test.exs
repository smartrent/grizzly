defmodule Grizzly.ZWave.Commands.HumidityControlSetpointCapabilitiesGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.HumidityControlSetpointCapabilitiesGet

  test "encode/1 correctly encodes command" do
    {:ok, command} = HumidityControlSetpointCapabilitiesGet.new(setpoint_type: :humidifier)
    assert <<1>> == HumidityControlSetpointCapabilitiesGet.encode_params(command)

    {:ok, command} = HumidityControlSetpointCapabilitiesGet.new(setpoint_type: :auto)
    assert <<3>> == HumidityControlSetpointCapabilitiesGet.encode_params(command)
  end

  test "decode/1 correctly decodes command" do
    assert {:ok, [setpoint_type: :humidifier]} ==
             HumidityControlSetpointCapabilitiesGet.decode_params(<<1>>)

    assert {:ok, [setpoint_type: :auto]} ==
             HumidityControlSetpointCapabilitiesGet.decode_params(<<3>>)
  end
end
