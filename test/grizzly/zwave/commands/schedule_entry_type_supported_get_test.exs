defmodule Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedGet

  test "creates the command and validates params" do
    {:ok, _command} = Commands.create(:schedule_entry_type_supported_get)
  end

  test "encodes params correctly" do
    {:ok, command} = Commands.create(:schedule_entry_type_supported_get)
    expected_binary = <<>>
    assert expected_binary == ScheduleEntryTypeSupportedGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<>>
    {:ok, []} = ScheduleEntryTypeSupportedGet.decode_params(binary_params)
  end
end
