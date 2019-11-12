defmodule Grizzly.CommandClass.NodeProvisioning.MetaExtension.ProductTypeTest do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.NodeProvisioning.MetaExtension.ProductType

  describe "decode binary" do
    test "when all is okay" do
      binary = <<0x00, 0x04, 0x40, 0x01, 0x20, 0x00>>

      expected_product_type_information = %ProductType{
        generic_device_class: :entry_control,
        specific_device_class: :door_lock,
        installer_icon: :icon_type_generic_entry_control
      }

      assert {:ok, expected_product_type_information} == ProductType.from_binary(binary)
    end

    test "when critical bit is 1 (which is not allowed)" do
      binary = <<0x01, 0x04, 0x40, 0x01, 0x20, 0x00>>

      assert {:error, :critical_bit_set} == ProductType.from_binary(binary)
    end
  end

  describe "encode into binary" do
    test "when all is okay" do
      product_type = %ProductType{
        generic_device_class: :sensor_binary,
        specific_device_class: :routing_sensor_binary,
        installer_icon: :icon_type_generic_sensor_notification
      }

      expected_binary = <<0x00, 0x04, 0x20, 0x01, 0x0C, 0x00>>

      assert {:ok, expected_binary} == ProductType.to_binary(product_type)
    end

    test "when generic type is not supported" do
      product_type = %ProductType{
        generic_device_class: :fake_generic_device_class,
        specific_device_class: :routing_sensor_binary,
        installer_icon: :icon_type_generic_sensor_notification
      }

      assert {:error, :invalid_generic_device_class} == ProductType.to_binary(product_type)
    end

    test "when specific type is not supported" do
      product_type = %ProductType{
        generic_device_class: :sensor_binary,
        specific_device_class: :not_a_sensor_binary,
        installer_icon: :icon_type_generic_sensor_notification
      }

      assert {:error, :invalid_specific_device_class} == ProductType.to_binary(product_type)
    end

    test "when icon type is not supported" do
      product_type = %ProductType{
        generic_device_class: :sensor_binary,
        specific_device_class: :routing_sensor_binary,
        installer_icon: :icon_type_generic_robot_dog_installer
      }

      assert {:error, :unknown_icon_type} == ProductType.to_binary(product_type)
    end
  end
end
