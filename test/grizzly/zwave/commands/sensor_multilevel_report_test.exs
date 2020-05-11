defmodule Grizzly.ZWave.Commands.SensorMultilevelReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SensorMultilevelReport

  test "creates the command and validates params" do
    params = [sensor_type: :temperature, scale: 2, value: 75.5]
    {:ok, _command} = SensorMultilevelReport.new(params)
  end

  test "encodes params correctly" do
    params = [sensor_type: :temperature, scale: 2, value: 75.5]
    {:ok, command} = SensorMultilevelReport.new(params)
    expected_binary = <<0x01, 0x01::size(3), 0x02::size(2), 0x02::size(3), 0x02, 0xF3>>
    assert expected_binary == SensorMultilevelReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01, 0x01::size(3), 0x02::size(2), 0x02::size(3), 0x02, 0xF3>>
    {:ok, params} = SensorMultilevelReport.decode_params(binary_params)
    assert Keyword.get(params, :sensor_type) == :temperature
    assert Keyword.get(params, :scale) == 2
    assert Keyword.get(params, :value) == 75.5
  end
end
