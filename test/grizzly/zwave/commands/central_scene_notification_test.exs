defmodule Grizzly.ZWave.Commands.CentralSceneNotificationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CentralSceneNotification

  test "creates the command and validates params" do
    params = [
      seq_number: 10,
      slow_refresh: true,
      key_attribute: :key_pressed_2_times,
      scene_number: 2
    ]

    {:ok, _command} = Commands.create(:central_scene_notification, params)
  end

  test "encodes params correctly" do
    params = [
      seq_number: 10,
      slow_refresh: true,
      key_attribute: :key_pressed_2_times,
      scene_number: 2
    ]

    {:ok, command} = Commands.create(:central_scene_notification, params)
    expected_params_binary = <<0x0A, 0x01::1, 0x00::4, 0x03::3, 0x02>>
    assert expected_params_binary == CentralSceneNotification.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<0x0A, 0x01::1, 0x00::4, 0x03::3, 0x02>>
    {:ok, params} = CentralSceneNotification.decode_params(nil, params_binary)
    assert Keyword.get(params, :seq_number) == 10
    assert Keyword.get(params, :slow_refresh) == true
    assert Keyword.get(params, :key_attribute) == :key_pressed_2_times
    assert Keyword.get(params, :scene_number) == 2
  end
end
