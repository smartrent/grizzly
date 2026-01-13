defmodule Grizzly.ZWave.Commands.ScheduleEntryLockWeekDayGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ScheduleEntryLockWeekDayGet

  test "creates the command and validates params" do
    params = [user_identifier: 2, schedule_slot_id: 3]
    {:ok, _command} = Commands.create(:schedule_entry_lock_week_day_get, params)
  end

  test "encodes params correctly" do
    params = [user_identifier: 2, schedule_slot_id: 3]
    {:ok, command} = Commands.create(:schedule_entry_lock_week_day_get, params)
    expected_binary = <<2, 3>>
    assert expected_binary == ScheduleEntryLockWeekDayGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<2, 3>>
    {:ok, expected_params} = ScheduleEntryLockWeekDayGet.decode_params(nil, binary_params)
    assert Keyword.get(expected_params, :user_identifier) == 2
    assert Keyword.get(expected_params, :schedule_slot_id) == 3
  end
end
