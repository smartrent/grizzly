defmodule Grizzly.ZWave.Commands.ScheduleEntryLockWeekDaySetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ScheduleEntryLockWeekDaySet

  test "creates the command and validates params" do
    params = [
      set_action: :erase,
      user_identifier: 20,
      schedule_slot_id: 5,
      day_of_week: 0,
      start_hour: 2,
      start_minute: 42,
      stop_hour: 2,
      stop_minute: 42
    ]

    {:ok, _command} = ScheduleEntryLockWeekDaySet.new(params)
  end

  test "encodes params correctly" do
    params = [
      set_action: :modify,
      user_identifier: 20,
      schedule_slot_id: 5,
      day_of_week: 0,
      start_hour: 2,
      start_minute: 42,
      stop_hour: 2,
      stop_minute: 42
    ]

    {:ok, command} = ScheduleEntryLockWeekDaySet.new(params)
    expected_binary = <<1, 20, 5, 0, 2, 42, 2, 42>>
    assert expected_binary == ScheduleEntryLockWeekDaySet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<1, 20, 5, 0, 2, 42, 2, 42>>
    {:ok, expected_params} = ScheduleEntryLockWeekDaySet.decode_params(binary_params)
    assert Keyword.get(expected_params, :set_action) == :modify
    assert Keyword.get(expected_params, :user_identifier) == 20
    assert Keyword.get(expected_params, :schedule_slot_id) == 5
    assert Keyword.get(expected_params, :day_of_week) == 0
    assert Keyword.get(expected_params, :start_hour) == 2
    assert Keyword.get(expected_params, :start_minute) == 42
    assert Keyword.get(expected_params, :stop_hour) == 2
    assert Keyword.get(expected_params, :stop_minute) == 42
  end
end
