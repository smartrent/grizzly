defmodule Grizzly.CommandClass.NodeProvisioning.MetaExtension.NameInformationTest do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.NodeProvisioning.MetaExtension.NameInformation

  test "serialize when all okay" do
    name_info = %NameInformation{name: "my Z-Wave node"}

    assert {:ok, <<0x64, 0x0E, 109, 121, 32, 90, 45, 87, 97, 118, 101, 32, 110, 111, 100, 101>>} ==
             NameInformation.to_binary(name_info)
  end

  test "does not serialize when there is a dash at the end" do
    name_info = %NameInformation{
      name: "this is a bad name-"
    }

    assert {:error, :ends_with_dash} == NameInformation.to_binary(name_info)
  end

  test "does not serialize when there is an underscore" do
    name_info = %NameInformation{
      name: "this_is_a_bad_name"
    }

    assert {:error, :contains_underscore} == NameInformation.to_binary(name_info)
  end

  test "does not serialize when the name is too long" do
    name_info = %NameInformation{
      name: "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
    }

    assert {:error, :name_too_long} == NameInformation.to_binary(name_info)
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
