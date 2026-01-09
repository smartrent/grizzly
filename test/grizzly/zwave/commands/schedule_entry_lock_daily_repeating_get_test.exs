defmodule Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingGet

  test "creates the command and validates params" do
    params = [user_identifier: 20, schedule_slot_id: 5]
    {:ok, _command} = Commands.create(:schedule_entry_lock_daily_repeating_get, params)
  end

  test "encodes params correctly" do
    params = [user_identifier: 20, schedule_slot_id: 5]
    {:ok, command} = Commands.create(:schedule_entry_lock_daily_repeating_get, params)
    expected_binary = <<20, 5>>
    assert expected_binary == ScheduleEntryLockDailyRepeatingGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<20, 5>>
    {:ok, expected_params} = ScheduleEntryLockDailyRepeatingGet.decode_params(binary_params)
    assert Keyword.get(expected_params, :user_identifier) == 20
    assert Keyword.get(expected_params, :schedule_slot_id) == 5
  end
end
