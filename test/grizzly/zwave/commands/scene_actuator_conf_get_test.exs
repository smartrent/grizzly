defmodule Grizzly.ZWave.Commands.SceneActuatorConfGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SceneActuatorConfGet

  test "creates the command and validates params" do
    params = [scene_id: 1]
    {:ok, _command} = SceneActuatorConfGet.new(params)
  end

  test "encodes params correctly" do
    params = [scene_id: 1]
    {:ok, command} = SceneActuatorConfGet.new(params)
    expected_binary = <<1>>
    assert expected_binary == SceneActuatorConfGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<1>>
    {:ok, params} = SceneActuatorConfGet.decode_params(params_binary)
    assert Keyword.get(params, :scene_id) == 1
  end
end
