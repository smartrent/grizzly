defmodule Grizzly.ZWave.Commands.ScheduleEntryLockWeekDayReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ScheduleEntryLockWeekDayReport

  test "creates the command and validates params" do
    params = [
      user_identifier: 20,
      schedule_slot_id: 5,
      day_of_week: 0,
      start_hour: 2,
      start_minute: 42,
      stop_hour: 2,
      stop_minute: 42
    ]

    {:ok, _command} = ScheduleEntryLockWeekDayReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      user_identifier: 20,
      schedule_slot_id: 5,
      day_of_week: 0,
      start_hour: 2,
      start_minute: 42,
      stop_hour: 2,
      stop_minute: 42
    ]

    {:ok, command} = ScheduleEntryLockWeekDayReport.new(params)
    expected_binary = <<20, 5, 0, 2, 42, 2, 42>>
    assert expected_binary == ScheduleEntryLockWeekDayReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<20, 5, 0, 2, 42, 2, 42>>
    {:ok, expected_params} = ScheduleEntryLockWeekDayReport.decode_params(binary_params)
    assert Keyword.get(expected_params, :user_identifier) == 20
    assert Keyword.get(expected_params, :schedule_slot_id) == 5
    assert Keyword.get(expected_params, :day_of_week) == 0
    assert Keyword.get(expected_params, :start_hour) == 2
    assert Keyword.get(expected_params, :start_minute) == 42
    assert Keyword.get(expected_params, :stop_hour) == 2
    assert Keyword.get(expected_params, :stop_minute) == 42
  end
end
