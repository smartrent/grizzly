defmodule Grizzly.ZWave.Commands.HumidityControlSetpointSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.HumidityControlSetpointSupportedReport

  test "encodes params correctly" do
    {:ok, command} =
      HumidityControlSetpointSupportedReport.new(setpoint_types: [:humidify, :auto])

    assert <<0b1010>> == HumidityControlSetpointSupportedReport.encode_params(command)
  end

  test "decodes params correctly" do
    assert {:ok, params} = HumidityControlSetpointSupportedReport.decode_params(<<0b1010>>)
    assert params[:setpoint_types] == [:humidify, :auto]
  end
end
