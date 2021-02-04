defmodule Grizzly.ZWave.Commands.SmartStartJoinStartedTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SmartStartJoinStarted
  alias GrizzlyTest.Utils

  test "creates the command and validates params" do
    params = [
      seq_number: 0x01,
      dsk: Utils.mkdsk()
    ]

    {:ok, _command} = SmartStartJoinStarted.new(params)
  end

  test "encodes params correctly" do
    params = [
      seq_number: 0x01,
      dsk: Utils.mkdsk()
    ]

    {:ok, command} = SmartStartJoinStarted.new(params)

    expected_binary =
      <<0x01, 0x10, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    assert expected_binary == SmartStartJoinStarted.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x01, 0x10, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    {:ok, params} = SmartStartJoinStarted.decode_params(binary_params)
    assert Keyword.get(params, :seq_number) == 1
    assert Keyword.get(params, :dsk) == Utils.mkdsk()
  end
end
