defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorReport

  test "creates the command and validates params" do
    params = [
      sensor_types: [:temperature, :luminance, :seismic_magnitude, :water_temperature]
    ]

    {:ok, _command} = Commands.create(:sensor_multilevel_supported_sensor_report, params)
  end

  test "encodes params correctly" do
    params = [
      sensor_types: [
        :temperature,
        :humidity,
        :seismic_magnitude,
        :water_temperature,
        :person_counter_exiting
      ]
    ]

    {:ok, command} = Commands.create(:sensor_multilevel_supported_sensor_report, params)
    expected_binary = <<17, 0, 64, 2, 0, 0, 0, 0, 0, 0, 128>>

    assert expected_binary ==
             SensorMultilevelSupportedSensorReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<17, 0, 64, 2, 0, 0, 0, 0, 0, 0, 128>>
    {:ok, params} = SensorMultilevelSupportedSensorReport.decode_params(binary_params)

    sensor_types = Keyword.get(params, :sensor_types)

    assert Enum.sort(sensor_types) ==
             Enum.sort([
               :temperature,
               :humidity,
               :seismic_magnitude,
               :water_temperature,
               :person_counter_exiting
             ])
  end
end
