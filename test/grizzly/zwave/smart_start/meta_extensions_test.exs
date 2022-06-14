defmodule Grizzly.ZWave.SmartStart.MetaExtensionTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Security
  alias Grizzly.ZWave.SmartStart.MetaExtension

  describe "advanced joining" do
    test "encode all keys" do
      assert <<0x6B, 0x01, 0x47>> ==
               MetaExtension.encode({:advanced_joining, Security.keys()})
    end

    test "invalid security keys are ignored" do
      assert <<0x6B, 0x01, 0x02>> ==
               MetaExtension.encode({:advanced_joining, [:red, :s2_authenticated]})
    end
  end

  describe "bootstrapping mode" do
    test "encodes security_2 mode" do
      assert <<0x6D, 0x01, 0x00>> == MetaExtension.encode({:bootstrapping_mode, :security_2})
    end

    test "encodes smart_start mode" do
      assert <<0x6D, 0x01, 0x01>> == MetaExtension.encode({:bootstrapping_mode, :smart_start})
    end

    test "encodes long_range mode" do
      assert <<0x6D, 0x01, 0x02>> == MetaExtension.encode({:bootstrapping_mode, :long_range})
    end

    test "parses security 2" do
      assert [bootstrapping_mode: :security_2] == MetaExtension.parse(<<0x6D, 0x01, 0x00>>)
    end

    test "parses smart start" do
      assert [bootstrapping_mode: :smart_start] == MetaExtension.parse(<<0x6D, 0x01, 0x01>>)
    end

    test "parses long range" do
      assert [bootstrapping_mode: :long_range] == MetaExtension.parse(<<0x6D, 0x01, 0x02>>)
    end
  end

  describe "location information" do
    test "encodes" do
      expected_bin = <<0x66, 0x0D, 108, 111, 99, 97, 116, 105, 111, 110, 49, 50, 51, 52, 48>>

      assert expected_bin == MetaExtension.encode({:location_information, "location12340"})
    end

    test "parses" do
      bin = <<0x66, 0x0D, 108, 111, 99, 97, 116, 105, 111, 110, 49, 50, 51, 52, 48>>

      assert [location_information: "location12340"] == MetaExtension.parse(bin)
    end
  end

  describe "max interval request" do
    test "encodes" do
      expected_binary = <<0x04, 0x01, 0x4C>>

      assert expected_binary == MetaExtension.encode({:max_inclusion_request_interval, 10368})
    end

    test "parses" do
      binary = <<0x04, 0x01, 0x54>>

      assert [max_inclusion_request_interval: 10752] == MetaExtension.parse(binary)
    end
  end

  describe "name information" do
    test "encodes with dot" do
      expected_bin = <<100, 12, 104, 101, 108, 108, 111, 92, 46, 119, 111, 114, 108, 100>>

      assert expected_bin == MetaExtension.encode({:name_information, "hello.world"})
    end

    test "parses" do
      bin = <<0x64, 0x0E, 109, 121, 32, 90, 45, 87, 97, 118, 101, 32, 110, 111, 100, 101>>

      assert [name_information: "my Z-Wave node"] == MetaExtension.parse(bin)
    end
  end

  describe "network status" do
    test "encodes when status is :not_in_network" do
      expected_binary = <<0x6E, 0x02, 0x01, 0x00>>

      assert expected_binary == MetaExtension.encode({:network_status, {1, :not_in_network}})
    end

    test "encodes when status is :included" do
      expected_binary = <<0x6E, 0x02, 0x01, 0x01>>

      assert expected_binary == MetaExtension.encode({:network_status, {1, :included}})
    end

    test "encodes when status is :failing" do
      expected_binary = <<0x6E, 0x02, 0x01, 0x02>>

      assert expected_binary == MetaExtension.encode({:network_status, {1, :failing}})
    end

    test "parses when status is :not_in_network - LR enabled" do
      binary = <<0x6E, 0x04, 0x01, 0x00, 0x00, 0x0A>>

      assert [network_status: {1, :not_in_network}] == MetaExtension.parse(binary)
    end

    test "parses when status is :not_in_network - LR NOT enabled" do
      binary = <<0x6E, 0x02, 0x01, 0x00>>

      assert [network_status: {1, :not_in_network}] == MetaExtension.parse(binary)
    end

    test "parses when status is :included - LR enabled" do
      binary = <<0x6E, 0x04, 0x01, 0x01, 0x00, 0x0A>>

      assert [network_status: {1, :included}] == MetaExtension.parse(binary)
    end

    test "parses when status is :included - LR NOT enabled" do
      binary = <<0x6E, 0x02, 0x01, 0x01>>

      assert [network_status: {1, :included}] == MetaExtension.parse(binary)
    end

    test "parses when status is :failing - LR enabled" do
      binary = <<0x6E, 0x04, 0x01, 0x02, 0x00, 0x0A>>

      assert [network_status: {1, :failing}] == MetaExtension.parse(binary)
    end

    test "parses when status is :failing - LR NOT enabled" do
      binary = <<0x6E, 0x02, 0x01, 0x02>>

      assert [network_status: {1, :failing}] == MetaExtension.parse(binary)
    end
  end

  describe "product id" do
    test "encodes" do
      expected_binary = <<0x02, 0x08, 0xFF, 0xFF, 0xEE, 0xEE, 0xAA, 0xAA, 0x01, 0x02>>
      extension_values = {0xFFFF, 0xEEEE, 0xAAAA, "1.2"}

      assert expected_binary == MetaExtension.encode({:product_id, extension_values})
    end

    test "parses" do
      binary = <<0x02, 0x08, 0x40, 0x01, 0x20, 0x00, 0x12, 0x34, 0x01, 0x02>>
      expected_values = {0x4001, 0x2000, 0x1234, "1.2"}

      assert [product_id: expected_values] == MetaExtension.parse(binary)
    end
  end

  describe "smart start inclusion setting" do
    test "encode pending setting" do
      expected_binary = <<0x69, 0x01, 0x00>>

      assert expected_binary == MetaExtension.encode({:smart_start_inclusion_setting, :pending})
    end

    test "encode passive setting" do
      expected_binary = <<0x69, 0x01, 0x02>>

      assert expected_binary == MetaExtension.encode({:smart_start_inclusion_setting, :passive})
    end

    test "encode ignored setting" do
      expected_binary = <<0x69, 0x01, 0x03>>

      assert expected_binary == MetaExtension.encode({:smart_start_inclusion_setting, :ignored})
    end

    test "parses pending setting" do
      binary = <<0x69, 0x01, 0x00>>

      assert [smart_start_inclusion_setting: :pending] == MetaExtension.parse(binary)
    end

    test "decodes passive setting" do
      binary = <<0x69, 0x01, 0x02>>

      assert [smart_start_inclusion_setting: :passive] == MetaExtension.parse(binary)
    end

    test "decodes ignored setting" do
      binary = <<0x69, 0x01, 0x03>>

      assert [smart_start_inclusion_setting: :ignored] == MetaExtension.parse(binary)
    end
  end

  describe "product type" do
    test "encodes" do
      expected_binary = <<0x00, 0x04, 0x20, 0x01, 0x0C, 0x00>>
      extension_values = {:sensor_binary, :routing_sensor_binary, :generic_sensor_notification}

      assert expected_binary == MetaExtension.encode({:product_type, extension_values})
    end

    test "parses" do
      binary = <<0x00, 0x04, 0x40, 0x01, 0x20, 0x00>>
      extension_values = {:entry_control, :door_lock, :generic_entry_control}

      assert [product_type: extension_values] == MetaExtension.parse(binary)
    end
  end

  describe "unknown extension" do
    test "encodes" do
      assert <<0xAA, 0x01, 0x04>> == MetaExtension.encode({:unknown, <<0xAA, 0x01, 0x04>>})
    end

    test "parses" do
      assert [unknown: <<0xAA, 0x02, 0x04, 0x04>>] ==
               MetaExtension.parse(<<0xAA, 0x02, 0x04, 0x04>>)
    end
  end
end
