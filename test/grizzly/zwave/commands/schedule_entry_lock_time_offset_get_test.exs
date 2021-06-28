defmodule Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetGet

  test "creates the command and validates params" do
    {:ok, _command} = ScheduleEntryLockTimeOffsetGet.new()
  end

  test "encodes params correctly" do
    {:ok, command} = ScheduleEntryLockTimeOffsetGet.new()
    expected_binary = <<>>
    assert expected_binary == ScheduleEntryLockTimeOffsetGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<>>
    {:ok, []} = ScheduleEntryLockTimeOffsetGet.decode_params(binary_params)
  end
end
