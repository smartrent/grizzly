defmodule Grizzly.ZWave.Commands.ScheduleEntryLockYearDayGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ScheduleEntryLockYearDayGet

  test "creates the command and validates params" do
    params = [user_identifier: 1, schedule_slot_id: 3]
    {:ok, _command} = ScheduleEntryLockYearDayGet.new(params)
  end

  test "encodes params correctly" do
    params = [user_identifier: 1, schedule_slot_id: 3]
    {:ok, command} = ScheduleEntryLockYearDayGet.new(params)
    expected_binary = <<1, 3>>
    assert expected_binary == ScheduleEntryLockYearDayGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<1, 3>>
    {:ok, expected_params} = ScheduleEntryLockYearDayGet.decode_params(binary_params)
    assert Keyword.get(expected_params, :user_identifier) == 1
    assert Keyword.get(expected_params, :schedule_slot_id) == 3
  end
end
