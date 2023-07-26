defmodule Grizzly.ZWave.Commands.SoundSwitchConfigurationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SoundSwitchConfigurationReport

  test "encodes params correctly" do
    {:ok, command} =
      SoundSwitchConfigurationReport.new(
        volume: 95,
        default_tone_identifier: 18
      )

    assert <<95, 18>> = SoundSwitchConfigurationReport.encode_params(command)
  end

  test "decodes params correctly" do
    params = <<95, 18>>

    assert {:ok, [volume: 95, default_tone_identifier: 18]} =
             SoundSwitchConfigurationReport.decode_params(params)
  end
end
