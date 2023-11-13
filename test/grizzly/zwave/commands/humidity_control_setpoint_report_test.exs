defmodule Grizzly.ZWave.Commands.HumidityControlSetpointReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.HumidityControlSetpointReport

  test "encodes params correctly" do
    {:ok, command} =
      HumidityControlSetpointReport.new(
        setpoint_type: :humidifier,
        value: 1.1,
        scale: :absolute
      )

    assert <<0x01, 0b00101001, 11>> ==
             HumidityControlSetpointReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary = <<0x01, 0b00101001, 11>>

    assert {:ok, params} = HumidityControlSetpointReport.decode_params(binary)
    assert params[:setpoint_type] == :humidifier
    assert params[:value] == 1.1
    assert params[:scale] == :absolute
  end
end
