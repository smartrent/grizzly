defmodule Grizzly.ZWave.Commands.AdminCodeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands

  test "creates the command and validates params" do
    assert {:ok, _command} = Commands.create(:admin_code_set, code: "1234")
  end

  describe "encodes params correctly" do
    test "setting user code available" do
      {:ok, command} = Commands.create(:admin_code_set, code: "0000")
      expected_binary = <<0x63, 0x0E, 0x04, 0x30, 0x30, 0x30, 0x30>>

      assert expected_binary == ZWave.to_binary(command)
    end

    test "setting user code occupied" do
      {:ok, command} = Commands.create(:admin_code_set, code: "12345")
      expected_binary = <<0x63, 0x0E, 0x05, 0x31, 0x32, 0x33, 0x34, 0x35>>

      assert expected_binary == ZWave.to_binary(command)
    end
  end

  test "decodes params correctly" do
    binary = <<0x63, 0x0E, 0x04, 0x34, 0x38, 0x32, 0x31>>
    {:ok, command} = ZWave.from_binary(binary)

    assert Command.param!(command, :code) == "4821"
  end
end
