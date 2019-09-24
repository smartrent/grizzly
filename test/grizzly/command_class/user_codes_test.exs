defmodule Grizzly.CommandClass.UserCode.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.UserCode

  test "makes an empty code" do
    assert [0, 0, 0, 0, 0, 0, 0, 0] == UserCode.empty_code()
  end

  test "occupied slot status to hex" do
    assert {:ok, 0x01} == UserCode.encode_status(:occupied)
  end

  test "available slot status to hex" do
    assert {:ok, 0x00} == UserCode.encode_status(:available)
  end

  test "hex to occupied slot status" do
    assert :occupied == UserCode.decode_slot_status(0x01)
  end

  test "hex to available slot status" do
    assert :available == UserCode.decode_slot_status(0x00)
  end

  test "encodes a user code" do
    assert {:ok, [0x31, 0x34, 0x36, 0x39]} == UserCode.encode_user_code([1, 4, 6, 9])
  end
end
