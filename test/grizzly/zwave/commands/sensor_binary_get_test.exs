defmodule Grizzly.ZWave.Commands.SensorBinaryGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SensorBinaryGet

  test "creates the command and validates params" do
    params = [sensor_type: :door_window]
    {:ok, _command} = Commands.create(:sensor_binary_get, params)
  end

  test "encodes params correctly" do
    params = [sensor_type: :door_window]
    {:ok, command} = Commands.create(:sensor_binary_get, params)
    expected_binary = <<0x0A>>
    assert expected_binary == SensorBinaryGet.encode_params(nil, command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0x0A>>
    {:ok, params} = SensorBinaryGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :sensor_type) == :door_window
  end
end
