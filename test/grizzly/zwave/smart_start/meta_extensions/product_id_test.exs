defmodule Grizzly.ZWave.SmartStart.MetaExtension.ProductIdTest do
  use ExUnit.Case, async: true
  alias Grizzly.ZWave.SmartStart.MetaExtension.ProductId

  test "make a new product id" do
    expected_product_id = %ProductId{
      manufacturer_id: 0x4001,
      product_type: 0x2000,
      product_id: 0x1234,
      application_version: {0x01, 0x02}
    }

    assert {:ok, expected_product_id} == ProductId.new(0x4001, 0x1234, 0x2000, {0x01, 0x02})
  end

  test "cannot create with an invalid manufacturer id argument" do
    assert {:error, :invalid_param_argument, :manufacturer_id, :hello} ==
             ProductId.new(:hello, 0xEEEE, 0xAAAA, {0x01, 0x2})
  end

  test "cannot create with invalid product type argument" do
    assert {:error, :invalid_param_argument, :product_type, :blue} ==
             ProductId.new(0xFFFF, 0xAAAA, :blue, {0x01, 0x02})
  end

  test "invalid product id argument" do
    assert {:error, :invalid_param_argument, :product_id, "green"} ==
             ProductId.new(0xFFFF, "green", 0xEEEE, {0x01, 0x02})
  end

  test "invalid application version argument" do
    assert {:error, :invalid_param_argument, :application_version, {}} ==
             ProductId.new(0xFFFF, 0xEEEE, 0xAAAA, {})

    assert {:error, :invalid_param_argument, :application_version, {:blue, 1}} ==
             ProductId.new(0xFFFF, 0xEEEE, 0xAAAA, {:blue, 1})

    assert {:error, :invalid_param_argument, :application_version, {1, :blue}} ==
             ProductId.new(0xFFFF, 0xEEEE, 0xAAAA, {1, :blue})

    assert {:error, :invalid_param_argument, :application_version, {"hello", "world"}} ==
             ProductId.new(0xFFFF, 0xEEEE, 0xAAAA, {"hello", "world"})
  end

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
end
