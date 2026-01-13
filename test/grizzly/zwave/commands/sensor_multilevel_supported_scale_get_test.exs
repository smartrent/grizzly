defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleGet

  test "creates the command and validates params" do
    params = [sensor_type: :temperature]
    {:ok, _command} = Commands.create(:sensor_multilevel_supported_scale_get, params)
  end

  test "encodes params correctly" do
    params = [sensor_type: :temperature]
    {:ok, command} = Commands.create(:sensor_multilevel_supported_scale_get, params)
    expected_binary = <<0x01>>
    assert expected_binary == SensorMultilevelSupportedScaleGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01>>
    {:ok, params} = SensorMultilevelSupportedScaleGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :sensor_type) == :temperature
  end
end
