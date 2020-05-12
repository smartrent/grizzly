defmodule Grizzly.ZWave.Commands.DoorLockOperationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands.DoorLockOperationSet

  test "creates the command and validates params" do
    assert {:ok, operation_set} = DoorLockOperationSet.new(mode: :secured)
  end

  describe "encodes params correctly" do
    test "mode secured" do
      {:ok, operation_set} = DoorLockOperationSet.new(mode: :secured)

      assert <<0x62, 0x01, 0xFF>> == ZWave.to_binary(operation_set)
    end

    test "mode unsecured" do
      {:ok, operation_set} = DoorLockOperationSet.new(mode: :unsecured)
      assert <<0x62, 0x01, 0x00>> == ZWave.to_binary(operation_set)
    end
  end

  describe "decodes params correctly" do
    test "mode secured" do
      binary = <<0x62, 0x01, 0x00>>
      {:ok, expected_command} = DoorLockOperationSet.new(mode: :unsecured)
      assert {:ok, expected_command} == ZWave.from_binary(binary)
    end

    test "mode unsecured" do
      binary = <<0x62, 0x01, 0xFF>>
      {:ok, expected_command} = DoorLockOperationSet.new(mode: :secured)

      assert {:ok, expected_command} == ZWave.from_binary(binary)
    end
  end
end
