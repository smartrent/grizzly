defmodule Grizzly.ZWave.Commands.SensorMultilevelGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SensorMultilevelGet

  test "creates the v1 command and validates params" do
    params = []
    {:ok, _command} = SensorMultilevelGet.new(params)
  end

  test "creates the v5 command and validates params" do
    params = [sensor_type: :temperature, scale: 2]
    {:ok, _command} = SensorMultilevelGet.new(params)
  end

  test "encodes v1 params correctly" do
    params = []
    {:ok, command} = SensorMultilevelGet.new(params)
    expected_binary = <<>>
    assert expected_binary == SensorMultilevelGet.encode_params(command)
  end

  test "encodes v5 params correctly" do
    params = [sensor_type: :temperature, scale: 2]
    {:ok, command} = SensorMultilevelGet.new(params)
    expected_binary = <<0x01, 0x00::size(3), 0x02::size(2), 0x00::size(3)>>
    assert expected_binary == SensorMultilevelGet.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<>>
    {:ok, []} = SensorMultilevelGet.decode_params(binary_params)
  end

  test "decodes v5 params correctly" do
    binary_params = <<0x01, 0x00::size(3), 0x02::size(2), 0x00::size(3)>>
    {:ok, params} = SensorMultilevelGet.decode_params(binary_params)
    assert Keyword.get(params, :sensor_type) == :temperature
    assert Keyword.get(params, :scale) == 2
  end
end
