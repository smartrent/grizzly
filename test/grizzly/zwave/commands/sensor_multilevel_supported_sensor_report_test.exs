defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorReport

  test "creates the command and validates params" do
    params = [sensor_types: [:air_temperature, :luminance, :air_flow, :moisture]]
    {:ok, _command} = SensorMultilevelSupportedSensorReport.new(params)
  end

  test "encodes params correctly" do
    params = [sensor_types: [:air_temperature, :luminance, :air_flow, :moisture]]
    {:ok, command} = SensorMultilevelSupportedSensorReport.new(params)
    expected_binary = <<160, 0, 64, 2>>
    assert expected_binary == SensorMultilevelSupportedSensorReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<160, 0, 64, 2>>
    {:ok, params} = SensorMultilevelSupportedSensorReport.decode_params(binary_params)

    sensor_types = Keyword.get(params, :sensor_types)

    assert Enum.sort(sensor_types) ==
             Enum.sort([
               :air_temperature,
               :luminance,
               :air_flow,
               :moisture
             ])
  end
end
