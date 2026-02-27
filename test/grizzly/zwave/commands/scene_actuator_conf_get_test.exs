defmodule Grizzly.ZWave.Commands.SceneActuatorConfGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  test "encodes params correctly" do
    params = [scene_id: 1]
    {:ok, command} = Commands.create(:scene_actuator_conf_get, params)
    expected_binary = <<0x2C, 0x02, 1>>
    assert expected_binary == Grizzly.encode_command(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x2C, 0x02, 1>>
    {:ok, command} = Grizzly.decode_command(params_binary)
    assert Keyword.get(command.params, :scene_id) == 1
  end
end
