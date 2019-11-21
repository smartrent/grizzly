defmodule Grizzly.SmartStart.MetaExtension.ProductIdTest do
  use ExUnit.Case, async: true
  alias Grizzly.SmartStart.MetaExtension.ProductId

  describe "decode binary" do
    test "when all is okay" do
      binary = <<0x02, 0x08, 0x40, 0x01, 0x20, 0x00, 0x12, 0x34, 0x01, 0x02>>

      expected_product_id_information = %ProductId{
        manufacturer_id: 0x4001,
        product_type: 0x2000,
        product_id: 0x1234,
        application_version: {0x01, 0x02}
      }

      assert {:ok, expected_product_id_information} == ProductId.from_binary(binary)
    end

    test "when critical bit is 1 (which is not allowed)" do
      binary = <<0x03, 0x08, 0x40, 0x01, 0x20, 0x00, 0x12, 0x34, 0x01, 0x02>>

      assert {:error, :critical_bit_set} == ProductId.from_binary(binary)
    end
  end

  describe "encode into binary" do
    test "when all is okay" do
      product_id = %ProductId{
        manufacturer_id: 0xFFFF,
        product_type: 0xEEEE,
        product_id: 0xAAAA,
        application_version: {0x01, 0x02}
      }

      expected_binary = <<0x02, 0x08, 0xFF, 0xFF, 0xEE, 0xEE, 0xAA, 0xAA, 0x01, 0x02>>

      assert {:ok, expected_binary} == ProductId.to_binary(product_id)
    end

    test "invalid manufacturer id argument" do
      product_id = %ProductId{
        manufacturer_id: :hello,
        product_type: 0xEEEE,
        product_id: 0xAAAA,
        application_version: {0x01, 0x02}
      }

      assert {:error, :invalid_param_argument, :manufacturer_id, :hello} ==
               ProductId.to_binary(product_id)
    end

    test "invalid product type argument" do
      product_id = %ProductId{
        manufacturer_id: 0xFFFF,
        product_type: :blue,
        product_id: 0xAAAA,
        application_version: {0x01, 0x02}
      }

      assert {:error, :invalid_param_argument, :product_type, :blue} ==
               ProductId.to_binary(product_id)
    end

    test "invalid product id argument" do
      product_id = %ProductId{
        manufacturer_id: 0xFFFF,
        product_type: 0xEEEE,
        product_id: "green",
        application_version: {0x01, 0x02}
      }

      assert {:error, :invalid_param_argument, :product_id, "green"} ==
               ProductId.to_binary(product_id)
    end

    test "invalid application version argument" do
      product_id = %ProductId{
        manufacturer_id: 0xFFFF,
        product_type: 0xEEEE,
        product_id: 0xAAAA,
        application_version: {}
      }

      assert {:error, :invalid_param_argument, :application_version, {}} ==
               ProductId.to_binary(product_id)

      product_id = %{product_id | application_version: {:blue, 1}}

      assert {:error, :invalid_param_argument, :application_version, {:blue, 1}} ==
               ProductId.to_binary(product_id)

      product_id = %{product_id | application_version: {1, :blue}}

      assert {:error, :invalid_param_argument, :application_version, {1, :blue}} ==
               ProductId.to_binary(product_id)

      product_id = %{product_id | application_version: {"world", "hello"}}

      assert {:error, :invalid_param_argument, :application_version, {"world", "hello"}} ==
               ProductId.to_binary(product_id)
    end
  end
end
