defmodule Grizzly.ZWave.Commands.UserCodeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.UserCodeSet

  test "creates the command and validates params" do
    assert {:ok, _command} = UserCodeSet.new(user_id: 1, status: :available, user_code: "1234")
  end

  describe "encodes params correctly" do
    test "setting user code available" do
      {:ok, command} = UserCodeSet.new(user_id: 9, user_id_status: :available, user_code: "0000")
      expected_binary = <<0x63, 0x01, 0x09, 0x00, 0x30, 0x30, 0x30, 0x30>>

      assert expected_binary == ZWave.to_binary(command)
    end

    test "setting user code occupied" do
      {:ok, command} = UserCodeSet.new(user_id: 5, user_id_status: :occupied, user_code: "12345")
      expected_binary = <<0x63, 0x01, 0x05, 0x01, 0x31, 0x32, 0x33, 0x34, 0x35>>

      assert expected_binary == ZWave.to_binary(command)
    end
  end

  test "decodes params correctly" do
    binary = <<0x63, 0x01, 0x07, 0x01, 0x34, 0x38, 0x32, 0x31>>
    {:ok, command} = ZWave.from_binary(binary)

    assert Command.param!(command, :user_id) == 7
    assert Command.param!(command, :user_id_status) == :occupied
    assert Command.param!(command, :user_code) == "4821"
  end
end
