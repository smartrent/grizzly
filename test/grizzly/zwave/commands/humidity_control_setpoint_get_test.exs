defmodule Grizzly.ZWave.Commands.HumidityControlSetpointGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.HumidityControlSetpointGet

  test "encode/1 correctly encodes command" do
    {:ok, command} = Commands.create(:humidity_control_setpoint_get, setpoint_type: :humidify)
    assert <<1>> == HumidityControlSetpointGet.encode_params(command)

    {:ok, command} = Commands.create(:humidity_control_setpoint_get, setpoint_type: :auto)
    assert <<3>> == HumidityControlSetpointGet.encode_params(command)
  end

  test "decode/1 correctly decodes command" do
    assert {:ok, [setpoint_type: :humidify]} ==
             HumidityControlSetpointGet.decode_params(<<1>>)

    assert {:ok, [setpoint_type: :auto]} ==
             HumidityControlSetpointGet.decode_params(<<3>>)
  end
end
