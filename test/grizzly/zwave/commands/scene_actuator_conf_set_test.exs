defmodule Grizzly.ZWave.Commands.SceneActuatorConfSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SceneActuatorConfSet

  test "creates the command and validates params" do
    params = [scene_id: 1, dimming_duration: [minutes: 2], level: 90, override: true]
    {:ok, _command} = SceneActuatorConfSet.new(params)
  end

  test "encodes params correctly" do
    params = [scene_id: 1, dimming_duration: [minutes: 2], level: 90, override: true]
    {:ok, command} = SceneActuatorConfSet.new(params)
    expected_binary = <<1, 0x81, 0x01::1, 0x00::7, 90>>
    assert expected_binary == SceneActuatorConfSet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<1, 0x81, 0x01::1, 0x00::7, 90>>
    {:ok, params} = SceneActuatorConfSet.decode_params(params_binary)
    assert Keyword.get(params, :scene_id) == 1
    assert Keyword.get(params, :level) == 90
    assert Keyword.get(params, :dimming_duration) == [minutes: 2]
    assert Keyword.get(params, :override) == true
  end
end
