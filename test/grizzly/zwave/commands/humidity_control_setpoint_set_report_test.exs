defmodule Grizzly.ZWave.Commands.HumidityControlSetpointSetReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.HumidityControlSetpointSetReport

  test "encodes params correctly" do
    {:ok, command} =
      Commands.create(
        :humidity_control_setpoint_set,
        setpoint_type: :humidify,
        value: 1.1,
        scale: :absolute
      )

    assert <<0x01, 0b00101001, 11>> ==
             HumidityControlSetpointSetReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary = <<0x01, 0b00101001, 11>>

    assert {:ok, params} = HumidityControlSetpointSetReport.decode_params(nil, binary)
    assert params[:setpoint_type] == :humidify
    assert params[:value] == 1.1
    assert params[:scale] == :absolute
  end
end
