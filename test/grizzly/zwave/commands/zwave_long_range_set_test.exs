defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZWaveLongRangeChannelSet

  test "correct command byte" do
    {:ok, cmd} = ZWaveLongRangeChannelSet.new()

    assert cmd.command_byte == 0x0A
  end

  test "correct name" do
    {:ok, cmd} = ZWaveLongRangeChannelSet.new()

    assert cmd.name == :zwave_long_range_channel_set
  end

  describe "encode" do
    test "version 4 with primary channel" do
      {:ok, cmd} = ZWaveLongRangeChannelSet.new(channel: :primary)

      assert ZWaveLongRangeChannelSet.encode_params(cmd) == <<0x01>>
    end

    test "version 4 with secondary channel" do
      {:ok, cmd} = ZWaveLongRangeChannelSet.new(channel: :secondary)

      assert ZWaveLongRangeChannelSet.encode_params(cmd) == <<0x02>>
    end
  end

  describe "parse" do
    test "version 4 with primary channel" do
      assert {:ok, [channel: :primary]} == ZWaveLongRangeChannelSet.decode_params(<<0x01>>)
    end

    test "version 4 with secondary channel" do
      assert {:ok, [channel: :secondary]} == ZWaveLongRangeChannelSet.decode_params(<<0x02>>)
    end
  end
end
