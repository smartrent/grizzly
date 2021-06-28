defmodule Grizzly.ZWave.Commands.ScheduleEntryLockEnableAllSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ScheduleEntryLockEnableAllSet

  test "creates the command and validates params" do
    params = [enabled: true]
    {:ok, _command} = ScheduleEntryLockEnableAllSet.new(params)
  end

  test "encodes params correctly" do
    params = [enabled: true]
    {:ok, command} = ScheduleEntryLockEnableAllSet.new(params)
    expected_binary = <<0x01>>
    assert expected_binary == ScheduleEntryLockEnableAllSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01>>
    {:ok, expected_params} = ScheduleEntryLockEnableAllSet.decode_params(binary_params)
    assert Keyword.get(expected_params, :enabled) == true
  end
end
