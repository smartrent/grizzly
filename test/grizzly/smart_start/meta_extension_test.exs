defmodule Grizzly.SmartStart.MetaExtensionTest do
  use ExUnit.Case, async: true

  alias Grizzly.SmartStart.MetaExtension

  alias Grizzly.SmartStart.MetaExtension.{
    AdvancedJoining,
    BootstrappingMode,
    LocationInformation,
    MaxInclusionRequestInterval,
    NameInformation,
    NetworkStatus,
    ProductId,
    ProductType,
    SmartStartInclusionSetting,
    UUID16
  }

  test "parse the meta extension advanced joining" do
    {:ok, expected_joining} = AdvancedJoining.new([:s2_unauthenticated])

    binary = <<0x6B, 0x01, 0x01>>

    assert {:ok, [expected_joining]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension bootstrapping mode" do
    {:ok, expected_bootstrapping} = BootstrappingMode.new(:smart_start)

    binary = <<0x6D, 0x01, 0x01>>

    assert {:ok, [expected_bootstrapping]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension location information" do
    {:ok, expected_location_information} = LocationInformation.new("location12340")
    binary = <<0x66, 0x0D, 108, 111, 99, 97, 116, 105, 111, 110, 49, 50, 51, 52, 48>>

    assert {:ok, [expected_location_information]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension max inclusion request interval" do
    {:ok, expected_request_interval} = MaxInclusionRequestInterval.new(10752)
    binary = <<0x04, 0x01, 0x54>>
    assert {:ok, [expected_request_interval]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension name information" do
    {:ok, expected_name_information} = NameInformation.new("my Z-Wave node")
    binary = <<0x64, 0x0E, 109, 121, 32, 90, 45, 87, 97, 118, 101, 32, 110, 111, 100, 101>>

    assert {:ok, [expected_name_information]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension network status" do
    {:ok, expected_network_status} = NetworkStatus.new(4, :included)
    binary = <<0x6E, 0x02, 0x04, 0x01>>

    assert {:ok, [expected_network_status]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension product id" do
    {:ok, expected_product_id} = ProductId.new(0xFFFF, 0xAAAA, 0xEEEE, {0x01, 0x02})
    binary = <<0x02, 0x08, 0xFF, 0xFF, 0xEE, 0xEE, 0xAA, 0xAA, 0x01, 0x02>>

    assert {:ok, [expected_product_id]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension product type" do
    {:ok, expected_product_type} =
      ProductType.new(
        :sensor_binary,
        :routing_sensor_binary,
        :icon_type_generic_sensor_notification
      )

    binary = <<0x00, 0x04, 0x20, 0x01, 0x0C, 0x00>>
    assert {:ok, [expected_product_type]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension for smart start inclusion setting" do
    {:ok, expected_inclusion_setting} = SmartStartInclusionSetting.new(:pending)
    binary = <<0x69, 0x01, 0x00>>

    assert {:ok, [expected_inclusion_setting]} == MetaExtension.extensions_from_binary(binary)
  end

  test "parse the meta extension for uuid16" do
    {:ok, expected_uuid16} = UUID16.new("0102030405060708090A141516171819", :hex)

    binary =
      <<0x06, 0x11, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14, 0x15,
        0x16, 0x17, 0x18, 0x19>>

    assert {:ok, [expected_uuid16]} == MetaExtension.extensions_from_binary(binary)
  end

  describe "parse arbitrary binary strings that contain meta extensions" do
    test "extensions: smart start inclusion setting and max inclusion request interval" do
      {:ok, expected_inclusion_setting} = SmartStartInclusionSetting.new(:pending)
      {:ok, expected_request_interval} = MaxInclusionRequestInterval.new(10752)

      binary = <<0x69, 0x01, 0x00, 0x04, 0x01, 0x54>>

      {:ok, extensions} = MetaExtension.extensions_from_binary(binary)

      assert Enum.member?(extensions, expected_inclusion_setting)
      assert Enum.member?(extensions, expected_request_interval)

      switched_binary = <<0x04, 0x01, 0x54, 0x69, 0x01, 0x00>>

      {:ok, extensions} = MetaExtension.extensions_from_binary(switched_binary)

      assert Enum.member?(extensions, expected_inclusion_setting)
      assert Enum.member?(extensions, expected_request_interval)
    end

    test "extensions: name information, location information, and uuid16" do
      {:ok, expected_location_information} = LocationInformation.new("location12340")

      location_information_binary =
        <<0x66, 0x0D, 108, 111, 99, 97, 116, 105, 111, 110, 49, 50, 51, 52, 48>>

      {:ok, expected_name_information} = NameInformation.new("my Z-Wave node")

      name_information_binary =
        <<0x64, 0x0E, 109, 121, 32, 90, 45, 87, 97, 118, 101, 32, 110, 111, 100, 101>>

      {:ok, expected_uuid16} = UUID16.new("0102030405060708090A141516171819", :hex)

      uuid_binary =
        <<0x06, 0x11, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14,
          0x15, 0x16, 0x17, 0x18, 0x19>>

      {:ok, extensions} =
        MetaExtension.extensions_from_binary(
          location_information_binary <> name_information_binary <> uuid_binary
        )

      assert Enum.member?(extensions, expected_location_information)
      assert Enum.member?(extensions, expected_name_information)
      assert Enum.member?(extensions, expected_uuid16)
    end

    test "extensions: product type, advanced joining, bootstrapping mode" do
      {:ok, expected_product_type} =
        ProductType.new(
          :sensor_binary,
          :routing_sensor_binary,
          :icon_type_generic_sensor_notification
        )

      product_type_binary = <<0x00, 0x04, 0x20, 0x01, 0x0C, 0x00>>
      {:ok, expected_joining} = AdvancedJoining.new([:s2_unauthenticated])

      joining_binary = <<0x6B, 0x01, 0x01>>
      {:ok, expected_bootstrapping} = BootstrappingMode.new(:smart_start)

      bootstrapping_binary = <<0x6D, 0x01, 0x01>>

      {:ok, extensions} =
        MetaExtension.extensions_from_binary(
          product_type_binary <> joining_binary <> bootstrapping_binary
        )

      assert Enum.member?(extensions, expected_product_type)
      assert Enum.member?(extensions, expected_joining)
      assert Enum.member?(extensions, expected_bootstrapping)
    end
  end

  test "does not parse junk" do
    assert {:error, :invalid_meta_extensions_binary} ==
             MetaExtension.extensions_from_binary(<<0x07, 0x12, 0x66, 0xAB, 0xCC>>)
  end

  test "handles TLV (type, length, value) binary string that does not map to an extension" do
    assert {:error, :invalid_meta_extensions_binary} ==
             MetaExtension.extensions_from_binary(<<0x90, 0x01, 0x00>>)
  end

  test "handles meta extension TLV with invalid data" do
    bootstrapping_binary = <<0x6D, 0x01, 0xA0>>

    assert {:error, BootstrappingMode, :invalid_mode} ==
             MetaExtension.extensions_from_binary(bootstrapping_binary)
  end

  test "turn a list of extensions into the right binary" do
    {:ok, name_information} = NameInformation.new("my Z-Wave node")
    {:ok, location_information} = LocationInformation.new("location12340")
    {:ok, bootstrapping} = BootstrappingMode.new(:smart_start)

    bootstrapping_binary = <<0x6D, 0x01, 0x01>>
    name_binary = <<0x64, 0x0E, 109, 121, 32, 90, 45, 87, 97, 118, 101, 32, 110, 111, 100, 101>>
    location_binary = <<0x66, 0x0D, 108, 111, 99, 97, 116, 105, 111, 110, 49, 50, 51, 52, 48>>

    expected_binary = name_binary <> bootstrapping_binary <> location_binary

    assert expected_binary ==
             MetaExtension.extensions_to_binary([
               name_information,
               bootstrapping,
               location_information
             ])
  end
end
