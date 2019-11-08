defmodule Grizzly.DSK.Test do
  use ExUnit.Case, async: true

  alias Grizzly.DSK

  test "turn the binary dsk into a the string dsk" do
    binary_dsk = <<196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>
    expected_string_dsk = "50285-18819-09924-30691-15973-33711-04005-03623"

    assert {:ok, expected_string_dsk} == DSK.binary_to_string(binary_dsk)
  end

  test "returns error if the dsk is too short" do
    assert {:error, :dsk_too_short} == DSK.string_to_binary("123")
  end

  test "returns error if the dsk is too long" do
    string_dsk = "50285-18819-09924-30691-15973-33711-04005-03623-111111"
    assert {:error, :dsk_too_long} == DSK.string_to_binary(string_dsk)
  end

  test "turn the string dsk into the binary dsk" do
    string_dsk = "50285-18819-09924-30691-15973-33711-04005-03623"

    expected_binary_dsk =
      <<196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    assert {:ok, expected_binary_dsk} == DSK.string_to_binary(string_dsk)
  end

  test "returns error if the dsk binary is too short" do
    assert {:error, :dsk_too_short} == DSK.binary_to_string(<<12, 23, 45>>)
  end

  test "returns error if the dsk binary is too long" do
    too_long_dsk_binary =
      <<196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39, 12>>

    assert {:error, :dsk_too_long} == DSK.binary_to_string(too_long_dsk_binary)
  end
end
