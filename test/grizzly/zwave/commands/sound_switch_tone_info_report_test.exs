defmodule Grizzly.ZWave.Commands.SoundSwitchToneInfoReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SoundSwitchToneInfoReport

  test "encodes params correctly" do
    {:ok, cmd} =
      Commands.create(:sound_switch_tone_info_report,
        tone_identifier: 15,
        tone_duration: 1024,
        name: "Alarm"
      )

    expected_binary = <<15, 1024::16, 5::8, "Alarm"::binary>>
    assert expected_binary == SoundSwitchToneInfoReport.encode_params(cmd)
  end

  test "decodes params correctly" do
    binary = <<15, 1024::16, 5::8, "Alarm"::binary>>
    {:ok, params} = SoundSwitchToneInfoReport.decode_params(binary)

    assert params == [
             tone_identifier: 15,
             tone_duration: 1024,
             name: "Alarm"
           ]
  end
end
