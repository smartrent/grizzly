defmodule Grizzly.ZWave.Commands.HumidityControlSetpointCapabilitiesReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.HumidityControlSetpointCapabilitiesReport

  test "encodes params correctly" do
    {:ok, command} =
      HumidityControlSetpointCapabilitiesReport.new(
        setpoint_type: :humidifier,
        min_value: 1.1,
        min_scale: :percentage,
        max_value: 10,
        max_scale: :absolute
      )

    assert <<0x01, 0b00100001, 11, 0b00001001, 10>> ==
             HumidityControlSetpointCapabilitiesReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary = <<0x01, 0b00100001, 11, 0b00001001, 10>>

    assert {:ok, params} = HumidityControlSetpointCapabilitiesReport.decode_params(binary)
    assert params[:setpoint_type] == :humidifier
    assert params[:min_value] == 1.1
    assert params[:min_scale] == :percentage
    assert params[:max_value] == 10
    assert params[:max_scale] == :absolute
  end
end
