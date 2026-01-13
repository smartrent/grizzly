defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ZWaveLongRangeChannelSet

  test "correct command byte" do
    {:ok, cmd} = Commands.create(:zwave_long_range_channel_set)

    assert cmd.command_byte == 0x0A
  end

  test "correct name" do
    {:ok, cmd} = Commands.create(:zwave_long_range_channel_set)

    assert cmd.name == :zwave_long_range_channel_set
  end

  describe "encode" do
    test "version 4 with primary channel" do
      {:ok, cmd} = Commands.create(:zwave_long_range_channel_set, channel: :primary)

      assert ZWaveLongRangeChannelSet.encode_params(nil, cmd) == <<0x01>>
    end

    test "version 4 with secondary channel" do
      {:ok, cmd} = Commands.create(:zwave_long_range_channel_set, channel: :secondary)

      assert ZWaveLongRangeChannelSet.encode_params(nil, cmd) == <<0x02>>
    end
  end

  describe "parse" do
    test "version 4 with primary channel" do
      assert {:ok, [channel: :primary]} == ZWaveLongRangeChannelSet.decode_params(nil, <<0x01>>)
    end

    test "version 4 with secondary channel" do
      assert {:ok, [channel: :secondary]} == ZWaveLongRangeChannelSet.decode_params(nil, <<0x02>>)
    end
  end
end
