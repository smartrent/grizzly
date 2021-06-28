defmodule Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedGet

  test "creates the command and validates params" do
    {:ok, _command} = ScheduleEntryTypeSupportedGet.new()
  end

  test "encodes params correctly" do
    {:ok, command} = ScheduleEntryTypeSupportedGet.new()
    expected_binary = <<>>
    assert expected_binary == ScheduleEntryTypeSupportedGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<>>
    {:ok, []} = ScheduleEntryTypeSupportedGet.decode_params(binary_params)
  end
end
