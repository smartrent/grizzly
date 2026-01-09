defmodule Grizzly.ZWave.Commands.DoorLockOperationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands

  test "creates the command and validates params" do
    assert {:ok, _} = Commands.create(:door_lock_operation_get)
  end

  test "encodes params correctly" do
    {:ok, operation_get} = Commands.create(:door_lock_operation_get)

    assert <<0x62, 0x02>> == ZWave.to_binary(operation_get)
  end

  test "decodes params correctly" do
    {:ok, operation_get} = Commands.create(:door_lock_operation_get)

    assert {:ok, operation_get} == ZWave.from_binary(<<0x62, 0x02>>)
  end
end
