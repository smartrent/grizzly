defmodule Grizzly.ZWave.SmartStart.MetaExtension.ProductTypeTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.SmartStart.MetaExtension.ProductType

  test "create a new product type" do
    expected_product_type = %ProductType{
      generic_device_class: :sensor_binary,
      specific_device_class: :routing_sensor_binary,
      installer_icon: :icon_type_generic_sensor_notification
    }

    assert {:ok, expected_product_type} ==
             ProductType.new(
               :sensor_binary,
               :routing_sensor_binary,
               :icon_type_generic_sensor_notification
             )
  end

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

  test "encode to binary" do
    product_type = %ProductType{
      generic_device_class: :sensor_binary,
      specific_device_class: :routing_sensor_binary,
      installer_icon: :icon_type_generic_sensor_notification
    }

    expected_binary = <<0x00, 0x04, 0x20, 0x01, 0x0C, 0x00>>

    assert {:ok, expected_binary} == ProductType.to_binary(product_type)
  end
end
