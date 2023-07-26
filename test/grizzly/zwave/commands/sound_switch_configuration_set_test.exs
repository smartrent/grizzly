defmodule Grizzly.ZWave.Commands.SoundSwitchConfigurationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SoundSwitchConfigurationSet

  test "encodes params correctly" do
    {:ok, command} =
      SoundSwitchConfigurationSet.new(
        volume: 95,
        default_tone_identifier: 18
      )

    assert <<95, 18>> = SoundSwitchConfigurationSet.encode_params(command)
  end

  test "decodes params correctly" do
    params = <<95, 18>>

    assert {:ok, [volume: 95, default_tone_identifier: 18]} =
             SoundSwitchConfigurationSet.decode_params(params)
  end
end
