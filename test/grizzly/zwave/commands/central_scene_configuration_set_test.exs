defmodule Grizzly.ZWave.Commands.CentralSceneConfigurationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CentralSceneConfigurationSet

  test "creates the command and validates params" do
    params = [slow_refresh: true]
    {:ok, _command} = Commands.create(:central_scene_configuration_set, params)
  end

  test "encodes params correctly" do
    params = [slow_refresh: true]
    {:ok, command} = Commands.create(:central_scene_configuration_set, params)
    expected_params_binary = <<0x01::1, 0x00::7>>
    assert expected_params_binary == CentralSceneConfigurationSet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x01::1, 0x00::7>>
    {:ok, params} = CentralSceneConfigurationSet.decode_params(params_binary)
    assert Keyword.get(params, :slow_refresh) == true
  end
end
