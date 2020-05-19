defmodule Grizzly.ZWave.Commands.SensorBinaryGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SensorBinaryGet

  test "creates the command and validates params" do
    params = [sensor_type: :door_window]
    {:ok, _command} = SensorBinaryGet.new(params)
  end

  test "encodes params correctly" do
    params = [sensor_type: :door_window]
    {:ok, command} = SensorBinaryGet.new(params)
    expected_binary = <<0x0A>>
    assert expected_binary == SensorBinaryGet.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0x0A>>
    {:ok, params} = SensorBinaryGet.decode_params(binary_params)
    assert Keyword.get(params, :sensor_type) == :door_window
  end
end
