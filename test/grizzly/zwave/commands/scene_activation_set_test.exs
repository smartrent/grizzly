defmodule Grizzly.ZWave.Commands.SceneActivationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SceneActivationSet

  test "creates the command and validates params" do
    params = [scene_id: 1, dimming_duration: :instantly]
    {:ok, _command} = SceneActivationSet.new(params)
  end

  test "encodes params correctly" do
    params = [scene_id: 1, dimming_duration: :instantly]
    {:ok, command} = SceneActivationSet.new(params)
    expected_binary = <<1, 0>>
    assert expected_binary == SceneActivationSet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<1, 0>>
    {:ok, params} = SceneActivationSet.decode_params(params_binary)
    assert Keyword.get(params, :scene_id) == 1
    assert Keyword.get(params, :dimming_duration) == :instantly
  end
end
