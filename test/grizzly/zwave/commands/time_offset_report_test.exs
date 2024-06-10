defmodule Grizzly.ZWave.Commands.TimeOffsetReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.TimeOffsetReport

  test "creates the command and validates params" do
    params = [
      sign_tzo: :minus,
      hour_tzo: 4,
      minute_tzo: 0,
      sign_offset_dst: :plus,
      minute_offset_dst: 60,
      month_start_dst: 3,
      day_start_dst: 23,
      hour_start_dst: 2,
      month_end_dst: 10,
      day_end_dst: 22,
      hour_end_dst: 2
    ]

    {:ok, _command} = TimeOffsetReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      sign_tzo: :minus,
      hour_tzo: 4,
      minute_tzo: 0,
      sign_offset_dst: :plus,
      minute_offset_dst: 60,
      month_start_dst: 3,
      day_start_dst: 23,
      hour_start_dst: 2,
      month_end_dst: 10,
      day_end_dst: 22,
      hour_end_dst: 2
    ]

    {:ok, command} = TimeOffsetReport.new(params)

    expected_binary =
      <<0x01::1, 4::7, 0, 0x00::1, 60::7, 3, 23, 2, 10, 22, 2>>

    assert expected_binary == TimeOffsetReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary =
      <<0x01::1, 4::7, 0, 0x00::1, 60::7, 3, 23, 2, 10, 22, 2>>

    {:ok, params} = TimeOffsetReport.decode_params(params_binary)
    assert Keyword.get(params, :sign_tzo) == :minus
    assert Keyword.get(params, :hour_tzo) == 4
    assert Keyword.get(params, :minute_tzo) == 0
    assert Keyword.get(params, :sign_offset_dst) == :plus
    assert Keyword.get(params, :minute_offset_dst) == 60
    assert Keyword.get(params, :month_start_dst) == 3
    assert Keyword.get(params, :day_start_dst) == 23
    assert Keyword.get(params, :hour_start_dst) == 2
    assert Keyword.get(params, :month_end_dst) == 10
    assert Keyword.get(params, :day_end_dst) == 22
    assert Keyword.get(params, :hour_end_dst) == 2
  end
end
