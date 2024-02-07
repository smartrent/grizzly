defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleReport

  test "creates the command and validates params" do
    params = [sensor_type: :temperature, supported_scales: [0, 1]]
    {:ok, _command} = SensorMultilevelSupportedScaleReport.new(params)
  end

  test "encodes params correctly" do
    params = [sensor_type: :temperature, supported_scales: [0, 1]]
    {:ok, command} = SensorMultilevelSupportedScaleReport.new(params)
    expected_binary = <<0x01, 0x00::4, 0x03::4>>
    assert expected_binary == SensorMultilevelSupportedScaleReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01, 0x00::4, 0x03::4>>
    {:ok, params} = SensorMultilevelSupportedScaleReport.decode_params(binary_params)
    assert :temperature == params[:sensor_type]
    assert [0, 1] == Enum.sort(params[:supported_scales])
  end
end
