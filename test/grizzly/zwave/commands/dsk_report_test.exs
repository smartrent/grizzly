defmodule Grizzly.ZWave.Commands.DSKReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.DSKReport

  test "creates the command and validates params" do
    params = [
      seq_number: 0x01,
      dsk: "50285-18819-09924-30691-15973-33711-04005-03623",
      add_mode: :learn
    ]

    assert {:ok, %Command{}} = DSKReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      seq_number: 0x01,
      dsk: "50285-18819-09924-30691-15973-33711-04005-03623",
      add_mode: :learn
    ]

    {:ok, command} = DSKReport.new(params)

    expected_binary =
      <<0x01, 0x00, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    assert expected_binary == DSKReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary =
      <<0x01, 0x00, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    {:ok, params} = DSKReport.decode_params(binary)

    assert Keyword.get(params, :seq_number) == 0x01
    assert Keyword.get(params, :add_mode) == :learn
    assert Keyword.get(params, :dsk) == "50285-18819-09924-30691-15973-33711-04005-03623"
  end
end
