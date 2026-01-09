defmodule Grizzly.ZWave.Commands.HailTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands

  test "creates the command and validates params" do
    assert {:ok, %Command{command_byte: 0x01, name: :hail}} = Commands.create(:hail)
  end

  test "encodes correctly" do
    {:ok, hail} = Commands.create(:hail)

    assert <<0x82, 0x01>> == ZWave.to_binary(hail)
  end

  test "decodes correctly" do
    {:ok, hail} = Commands.create(:hail)

    assert {:ok, hail} == ZWave.from_binary(<<0x82, 0x01>>)
  end
end
