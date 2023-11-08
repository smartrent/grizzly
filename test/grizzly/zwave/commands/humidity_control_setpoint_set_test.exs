defmodule Grizzly.ZWave.Commands.HumidityControlSetpointSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.HumidityControlSetpointSet

  test "encodes params correctly" do
    {:ok, command} =
      HumidityControlSetpointSet.new(
        setpoint_type: :humidifier,
        value: 1.1,
        scale: :absolute
      )

    assert <<0x01, 0b00101001, 11>> ==
             HumidityControlSetpointSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary = <<0x01, 0b00101001, 11>>

    assert {:ok, params} = HumidityControlSetpointSet.decode_params(binary)
    assert params[:setpoint_type] == :humidifier
    assert params[:value] == 1.1
    assert params[:scale] == :absolute
  end
end
