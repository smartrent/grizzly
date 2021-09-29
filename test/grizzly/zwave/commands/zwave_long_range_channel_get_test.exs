defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZWaveLongRangeChannelGet

  test "correct command byte" do
    {:ok, cmd} = ZWaveLongRangeChannelGet.new()

    assert cmd.command_byte == 0x0D
  end

  test "correct name" do
    {:ok, cmd} = ZWaveLongRangeChannelGet.new()

    assert cmd.name == :zwave_long_range_channel_get
  end

  test "encodes version 4" do
    {:ok, cmd} = ZWaveLongRangeChannelGet.new()

    assert ZWaveLongRangeChannelGet.encode_params(cmd) == <<>>
  end

  test "parses version 4" do
    assert {:ok, []} == ZWaveLongRangeChannelGet.decode_params(<<>>)
  end
end
