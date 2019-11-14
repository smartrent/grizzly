defmodule Grizzly.CommandClass.NodeProvisioning.MetaExtension.MaxInclusionRequestIntervalTest do
  use ExUnit.Case, async: true
  alias Grizzly.CommandClass.NodeProvisioning.MetaExtension.MaxInclusionRequestInterval

  describe "decode binary" do
    test "when all is okay" do
      binary = <<0x04, 0x01, 0x54>>

      expected_product_id_information = %MaxInclusionRequestInterval{
        interval: 10752
      }

      assert {:ok, expected_product_id_information} ==
               MaxInclusionRequestInterval.from_binary(binary)
    end

    test "when critical bit is 1 (which is not allowed)" do
      binary = <<0x05, 0x01, 0x10>>

      assert {:error, :critical_bit_set} == MaxInclusionRequestInterval.from_binary(binary)
    end
  end

  describe "encode into binary" do
    test "when all is okay" do
      miri = %MaxInclusionRequestInterval{
        interval: 10368
      }

      expected_binary = <<0x04, 0x01, 0x4C>>

      assert {:ok, expected_binary} == MaxInclusionRequestInterval.to_binary(miri)
    end

    test "when the interval is too small" do
      miri = %MaxInclusionRequestInterval{
        interval: 639
      }

      assert {:error, :interval_too_small} == MaxInclusionRequestInterval.to_binary(miri)
    end

    test "when the interval is too big" do
      miri = %MaxInclusionRequestInterval{
        interval: 13000
      }

      assert {:error, :interval_too_big} == MaxInclusionRequestInterval.to_binary(miri)
    end

    test "when the interval is not a 128 second step" do
      miri = %MaxInclusionRequestInterval{
        interval: 1300
      }

      assert {:error, :interval_step_invalid} == MaxInclusionRequestInterval.to_binary(miri)
    end
  end
end
