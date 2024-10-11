defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleReport

  test "creates the command and validates params" do
    params = [sensor_type: :temperature, supported_scales: [:c, :f]]
    {:ok, _command} = SensorMultilevelSupportedScaleReport.new(params)
  end

  test "encodes params correctly" do
    params = [sensor_type: :temperature, supported_scales: [:c, :f]]
    {:ok, command} = SensorMultilevelSupportedScaleReport.new(params)
    expected_binary = <<0x01, 0x00::4, 0x03::4>>
    assert expected_binary == SensorMultilevelSupportedScaleReport.encode_params(command)

    params = [sensor_type: :radon_concentration, supported_scales: [:picocuries_per_liter]]
    {:ok, command} = SensorMultilevelSupportedScaleReport.new(params)
    expected_binary = <<0x25, 0x00::4, 0x02::4>>

    assert expected_binary ==
             SensorMultilevelSupportedScaleReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01, 0x00::4, 0x03::4>>
    {:ok, params} = SensorMultilevelSupportedScaleReport.decode_params(binary_params)
    assert :temperature == params[:sensor_type]
    assert [:c, :f] == Enum.sort(params[:supported_scales])

    binary_params = <<0x25, 0x00::4, 0x02::4>>
    {:ok, params} = SensorMultilevelSupportedScaleReport.decode_params(binary_params)
    assert :radon_concentration == params[:sensor_type]
    assert [:picocuries_per_liter] == Enum.sort(params[:supported_scales])
  end
end
