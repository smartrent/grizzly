defmodule Grizzly.ZWave.Commands.SoundSwitchConfigurationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SoundSwitchConfigurationSet

  test "encodes params correctly" do
    {:ok, command} =
      Commands.create(
        :sound_switch_configuration_set,
        volume: 95,
        default_tone_identifier: 18
      )

    assert <<95, 18>> = SoundSwitchConfigurationSet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params = <<95, 18>>

    assert {:ok, [volume: 95, default_tone_identifier: 18]} =
             SoundSwitchConfigurationSet.decode_params(nil, params)
  end
end
