defmodule Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetSet

  test "creates the command and validates params" do
    params = [
      sign_tzo: :plus,
      hour_tzo: 4,
      minute_tzo: 20,
      sign_offset_dst: :plus,
      minute_offset_dst: 100
    ]

    {:ok, _command} = Commands.create(:schedule_entry_lock_time_offset_set, params)
  end

  test "encodes params correctly" do
    params = [
      sign_tzo: :plus,
      hour_tzo: 4,
      minute_tzo: 20,
      sign_offset_dst: :plus,
      minute_offset_dst: 100
    ]

    {:ok, command} = Commands.create(:schedule_entry_lock_time_offset_set, params)
    expected_binary = <<0::1, 4::7, 20::8, 0::1, 100::7>>
    assert expected_binary == ScheduleEntryLockTimeOffsetSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0::1, 4::7, 20::8, 0::1, 100::7>>
    {:ok, expected_params} = ScheduleEntryLockTimeOffsetSet.decode_params(binary_params)
    assert Keyword.get(expected_params, :sign_tzo) == :plus
    assert Keyword.get(expected_params, :hour_tzo) == 4
    assert Keyword.get(expected_params, :minute_tzo) == 20
    assert Keyword.get(expected_params, :sign_offset_dst) == :plus
    assert Keyword.get(expected_params, :minute_offset_dst) == 100
  end
end
