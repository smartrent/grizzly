defmodule Grizzly.ZWave.Commands.HumidityControlSetpointCapabilitiesGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.HumidityControlSetpointCapabilitiesGet

  test "encode/1 correctly encodes command" do
    {:ok, command} =
      Commands.create(:humidity_control_setpoint_capabilities_get, setpoint_type: :humidify)

    assert <<1>> == HumidityControlSetpointCapabilitiesGet.encode_params(nil, command)

    {:ok, command} =
      Commands.create(:humidity_control_setpoint_capabilities_get, setpoint_type: :auto)

    assert <<3>> == HumidityControlSetpointCapabilitiesGet.encode_params(nil, command)
  end

  test "decode/1 correctly decodes command" do
    assert {:ok, [setpoint_type: :humidify]} ==
             HumidityControlSetpointCapabilitiesGet.decode_params(nil, <<1>>)

    assert {:ok, [setpoint_type: :auto]} ==
             HumidityControlSetpointCapabilitiesGet.decode_params(nil, <<3>>)
  end
end
