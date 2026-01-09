defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ZWaveLongRangeChannelReport

  test "correct command byte" do
    {:ok, cmd} = Commands.create(:zwave_long_range_channel_report)

    assert cmd.command_byte == 0x0E
  end

  test "correct name" do
    {:ok, cmd} = Commands.create(:zwave_long_range_channel_report)

    assert cmd.name == :zwave_long_range_channel_report
  end

  describe "encode" do
    test "version 4 with primary channel" do
      {:ok, cmd} = Commands.create(:zwave_long_range_channel_report, channel: :primary)

      assert ZWaveLongRangeChannelReport.encode_params(cmd) == <<0x01>>
    end

    test "version 4 with secondary channel" do
      {:ok, cmd} = Commands.create(:zwave_long_range_channel_report, channel: :secondary)

      assert ZWaveLongRangeChannelReport.encode_params(cmd) == <<0x02>>
    end
  end

  describe "parse" do
    test "version 4 with primary channel" do
      assert {:ok, [channel: :primary]} == ZWaveLongRangeChannelReport.decode_params(<<0x01>>)
    end

    test "version 4 with secondary channel" do
      assert {:ok, [channel: :secondary]} == ZWaveLongRangeChannelReport.decode_params(<<0x02>>)
    end
  end
end
