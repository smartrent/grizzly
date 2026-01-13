defmodule Grizzly.ZWave.Commands.HumidityControlSetpointScaleSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.HumidityControlSetpointScaleSupportedGet

  test "encode/1 correctly encodes command" do
    {:ok, command} =
      Commands.create(:humidity_control_setpoint_scale_supported_get, setpoint_type: :humidify)

    assert <<1>> == HumidityControlSetpointScaleSupportedGet.encode_params(nil, command)

    {:ok, command} =
      Commands.create(:humidity_control_setpoint_scale_supported_get, setpoint_type: :auto)

    assert <<3>> == HumidityControlSetpointScaleSupportedGet.encode_params(nil, command)
  end

  test "decode/1 correctly decodes command" do
    assert {:ok, [setpoint_type: :humidify]} ==
             HumidityControlSetpointScaleSupportedGet.decode_params(nil, <<1>>)

    assert {:ok, [setpoint_type: :auto]} ==
             HumidityControlSetpointScaleSupportedGet.decode_params(nil, <<3>>)
  end
end
