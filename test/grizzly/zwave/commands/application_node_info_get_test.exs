defmodule Grizzly.ZWave.Commands.ApplicationNodeInfoGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands.ApplicationNodeInfoGet

  test "creates the command and validates params" do
    assert {:ok, command} = ApplicationNodeInfoGet.new()
    assert command.command_byte == 0x0C
  end

  test "encodes params correctly" do
    {:ok, command} = ApplicationNodeInfoGet.new()
    assert <<0x5F, 0x0C>> == ZWave.to_binary(command)
  end

  test "decodes params correctly" do
    binary = <<0x5F, 0x0C>>
    {:ok, expected_command} = ApplicationNodeInfoGet.new()

    assert {:ok, expected_command} == ZWave.from_binary(binary)
  end
end
