defmodule Grizzly.SmartStart.MetaExtension.LocationInformationTest do
  use ExUnit.Case, async: true

  alias Grizzly.SmartStart.MetaExtension.LocationInformation

  test "make a new location information" do
    expected_location_information = %LocationInformation{location: "location12340"}

    assert {:ok, expected_location_information} == LocationInformation.new("location12340")
  end

  test "does not make a new location information when there is a dash at the end" do
    assert {:error, :ends_with_dash} == LocationInformation.new("this is a bad location-")
  end

  test "does not make a new location information when there is an underscore in the location" do
    assert {:error, :contains_underscore} == LocationInformation.new("this_is_a_bad location")
  end

  test "does not make a new location when a sublocation ends with a dash" do
    assert {:error, :sublocation_ends_with_dash} ==
             LocationInformation.new("this.is.a-.bad.location")
  end

  test "does not make a new location when the location is too long" do
    location = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
    assert {:error, :location_too_long} == LocationInformation.new(location)
  end

  test "serialize when all okay" do
    location_info = %LocationInformation{location: "location12340"}

    assert {:ok, <<0x66, 0x0D, 108, 111, 99, 97, 116, 105, 111, 110, 49, 50, 51, 52, 48>>} ==
             LocationInformation.to_binary(location_info)
  end

  test "encodes a dot (.) correctly" do
    location_info = %LocationInformation{
      location: "hello.world"
    }

    expected_bin = <<102, 11, 104, 101, 108, 108, 111, 46, 119, 111, 114, 108, 100>>

    assert {:ok, expected_bin} == LocationInformation.to_binary(location_info)
  end

  test "deserializes when all okay" do
    binary = <<0x66, 0x0E, 109, 121, 32, 90, 45, 87, 97, 118, 101, 32, 110, 111, 100, 101>>

    expected_location_info = %LocationInformation{location: "my Z-Wave node"}

    assert {:ok, expected_location_info} == LocationInformation.from_binary(binary)
  end

  test "deserializes when there is a period in location" do
    bin = <<102, 12, 104, 101, 108, 108, 111, 46, 119, 111, 114, 108, 100>>

    expected_location_info = %LocationInformation{
      location: "hello.world"
    }

    assert {:ok, expected_location_info} == LocationInformation.from_binary(bin)
  end
end
