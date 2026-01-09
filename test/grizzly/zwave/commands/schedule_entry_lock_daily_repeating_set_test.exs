defmodule Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingSet

  test "creates the command and validates params" do
    params = [
      set_action: :modify,
      user_identifier: 20,
      schedule_slot_id: 5,
      week_days: [:sunday, :tuesday],
      start_hour: 2,
      start_minute: 42,
      duration_hour: 2,
      duration_minute: 42
    ]

    {:ok, _command} = Commands.create(:schedule_entry_lock_daily_repeating_set, params)
  end

  test "encodes params correctly" do
    params = [
      set_action: :modify,
      user_identifier: 20,
      schedule_slot_id: 5,
      week_days: [:sunday, :monday],
      start_hour: 2,
      start_minute: 42,
      duration_hour: 2,
      duration_minute: 42
    ]

    {:ok, command} = Commands.create(:schedule_entry_lock_daily_repeating_set, params)
    expected_bitmask = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 1::1, 1::1>>
    expected_binary = <<1, 20, 5>> <> expected_bitmask <> <<2, 42, 2, 42>>
    assert expected_binary == ScheduleEntryLockDailyRepeatingSet.encode_params(command)
  end

  test "decodes params correctly" do
    week_day_bitmask = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 1::1, 1::1>>
    binary_params = <<1, 20, 5>> <> week_day_bitmask <> <<2, 42, 2, 42>>
    {:ok, expected_params} = ScheduleEntryLockDailyRepeatingSet.decode_params(binary_params)
    assert Keyword.get(expected_params, :set_action) == :modify
    assert Keyword.get(expected_params, :user_identifier) == 20
    assert Keyword.get(expected_params, :schedule_slot_id) == 5
    assert Enum.sort(Keyword.get(expected_params, :week_days)) == Enum.sort([:sunday, :monday])
    assert Keyword.get(expected_params, :start_hour) == 2
    assert Keyword.get(expected_params, :start_minute) == 42
    assert Keyword.get(expected_params, :duration_hour) == 2
    assert Keyword.get(expected_params, :duration_minute) == 42
  end
end
