defmodule Grizzly.ZWave.Commands.ScheduleEntryLockYearDaySetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ScheduleEntryLockYearDaySet

  test "creates the command and validates params" do
    params = [
      set_action: :erase,
      user_identifier: 20,
      schedule_slot_id: 5,
      start_year: 97,
      start_month: 10,
      start_day: 7,
      start_hour: 2,
      start_minute: 42,
      stop_year: 99,
      stop_month: 12,
      stop_day: 31,
      stop_hour: 2,
      stop_minute: 42
    ]

    {:ok, _command} = Commands.create(:schedule_entry_lock_year_day_set, params)
  end

  test "encodes params correctly" do
    params = [
      set_action: :erase,
      user_identifier: 20,
      schedule_slot_id: 5,
      start_year: 97,
      start_month: 10,
      start_day: 7,
      start_hour: 2,
      start_minute: 42,
      stop_year: 99,
      stop_month: 12,
      stop_day: 31,
      stop_hour: 2,
      stop_minute: 42
    ]

    {:ok, command} = Commands.create(:schedule_entry_lock_year_day_set, params)
    expected_binary = <<0, 20, 5, 97, 10, 7, 2, 42, 99, 12, 31, 2, 42>>
    assert expected_binary == ScheduleEntryLockYearDaySet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0, 20, 5, 97, 10, 7, 2, 42, 99, 12, 31, 2, 42>>
    {:ok, expected_params} = ScheduleEntryLockYearDaySet.decode_params(nil, binary_params)
    assert Keyword.get(expected_params, :set_action) == :erase
    assert Keyword.get(expected_params, :user_identifier) == 20
    assert Keyword.get(expected_params, :schedule_slot_id) == 5
    assert Keyword.get(expected_params, :start_year) == 97
    assert Keyword.get(expected_params, :start_month) == 10
    assert Keyword.get(expected_params, :start_day) == 7
    assert Keyword.get(expected_params, :start_hour) == 2
    assert Keyword.get(expected_params, :start_minute) == 42
    assert Keyword.get(expected_params, :stop_year) == 99
    assert Keyword.get(expected_params, :stop_month) == 12
    assert Keyword.get(expected_params, :stop_day) == 31
    assert Keyword.get(expected_params, :stop_hour) == 2
    assert Keyword.get(expected_params, :stop_minute) == 42
  end
end
