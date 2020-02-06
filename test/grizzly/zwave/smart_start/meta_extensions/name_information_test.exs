defmodule Grizzly.ZWave.SmartStart.MetaExtension.NameInformationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.SmartStart.MetaExtension.NameInformation

  test "creates a new name information when name is okay" do
    expected_name = %NameInformation{name: "my lock"}

    assert {:ok, expected_name} == NameInformation.new("my lock")
  end

  test "does not create a name information when the name is too long" do
    name = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
    assert {:error, :name_too_long} == NameInformation.new(name)
  end

  test "does not create a name information when the name ends with a dash" do
    assert {:error, :ends_with_dash} == NameInformation.new("this is a bad name-")
  end

  test "does not create a name information when the name contains underscores" do
    assert {:error, :contains_underscore} == NameInformation.new("this_is_a_bad_name")
  end

  test "serialize when all okay" do
    name_info = %NameInformation{name: "my Z-Wave node"}

    assert {:ok, <<0x64, 0x0E, 109, 121, 32, 90, 45, 87, 97, 118, 101, 32, 110, 111, 100, 101>>} ==
             NameInformation.to_binary(name_info)
  end

  test "encodes a dot (.) correctly" do
    name_info = %NameInformation{
      name: "hello.world"
    }

    expected_bin = <<100, 12, 104, 101, 108, 108, 111, 92, 46, 119, 111, 114, 108, 100>>

    assert {:ok, expected_bin} == NameInformation.to_binary(name_info)
  end

  test "deserializes when all okay" do
    binary = <<0x64, 0x0E, 109, 121, 32, 90, 45, 87, 97, 118, 101, 32, 110, 111, 100, 101>>

    expected_name_info = %NameInformation{name: "my Z-Wave node"}

    assert {:ok, expected_name_info} == NameInformation.from_binary(binary)
  end

  test "deserializes when there is a period in name" do
    bin = <<100, 12, 104, 101, 108, 108, 111, 92, 46, 119, 111, 114, 108, 100>>

    expected_name_info = %NameInformation{
      name: "hello.world"
    }

    assert {:ok, expected_name_info} == NameInformation.from_binary(bin)
  end
end
