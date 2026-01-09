defmodule Grizzly.ZWave.Commands.HumidityControlSetpointScaleSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.HumidityControlSetpointScaleSupportedReport

  test "encode/1 correctly encodes command" do
    {:ok, command} =
      Commands.create(:humidity_control_setpoint_scale_supported_report,
        scales: [:percentage, :absolute]
      )

    assert <<0b11>> == HumidityControlSetpointScaleSupportedReport.encode_params(command)
  end

  test "decode/1 correctly decodes command" do
    assert {:ok, params} = HumidityControlSetpointScaleSupportedReport.decode_params(<<0b11>>)
    assert params[:scales] == [:percentage, :absolute]
  end
end
