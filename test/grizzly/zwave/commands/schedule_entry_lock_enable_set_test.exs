defmodule Grizzly.ZWave.Commands.ScheduleEntryLockEnableSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ScheduleEntryLockEnableSet

  test "creates the command and validates params" do
    params = [user_identifier: 10, enabled: true]
    {:ok, _command} = ScheduleEntryLockEnableSet.new(params)
  end

  test "encodes params correctly" do
    params = [user_identifier: 10, enabled: true]
    {:ok, command} = ScheduleEntryLockEnableSet.new(params)
    expected_binary = <<10, 0x01>>
    assert expected_binary == ScheduleEntryLockEnableSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<10, 0x01>>
    {:ok, expected_params} = ScheduleEntryLockEnableSet.decode_params(binary_params)
    assert Keyword.get(expected_params, :user_identifier) == 10
    assert Keyword.get(expected_params, :enabled) == true
  end
end
