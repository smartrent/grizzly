defmodule Grizzly.ZWave.Commands.SensorMultilevelGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SensorMultilevelGet

  test "creates the v1 command and validates params" do
    params = []
    {:ok, _command} = Commands.create(:sensor_multilevel_get, params)
  end

  test "creates the v5 command and validates params" do
    params = [sensor_type: :temperature, scale: :f]
    {:ok, _command} = Commands.create(:sensor_multilevel_get, params)
  end

  test "encodes v1 params correctly" do
    params = []
    {:ok, command} = Commands.create(:sensor_multilevel_get, params)
    expected_binary = <<>>
    assert expected_binary == SensorMultilevelGet.encode_params(nil, command)
  end

  test "encodes v5 params correctly" do
    params = [sensor_type: :temperature, scale: :f]
    {:ok, command} = Commands.create(:sensor_multilevel_get, params)
    expected_binary = <<0x01, 0x00::3, 0x01::2, 0x00::3>>
    assert expected_binary == SensorMultilevelGet.encode_params(nil, command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<>>
    {:ok, []} = SensorMultilevelGet.decode_params(nil, binary_params)
  end

  test "decodes v5 params correctly" do
    binary_params = <<0x01, 0x00::3, 0x01::2, 0x00::3>>
    {:ok, params} = SensorMultilevelGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :sensor_type) == :temperature
    assert Keyword.get(params, :scale) == :f

    binary_params = <<0x01, 0x00::3, 0x02::2, 0x00::3>>
    {:ok, params} = SensorMultilevelGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :sensor_type) == :temperature
    assert Keyword.get(params, :scale) == :unknown
  end
end
