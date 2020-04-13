defmodule Grizzly.ZWave.SmartStart.MetaExtension.MaxInclusionRequestIntervalTest do
  use ExUnit.Case, async: true
  alias Grizzly.ZWave.SmartStart.MetaExtension.MaxInclusionRequestInterval

  test "make a new MaxInclusionRequestInterval" do
    expected_request_interval = %MaxInclusionRequestInterval{interval: 10752}
    assert {:ok, expected_request_interval} == MaxInclusionRequestInterval.new(10752)
  end

  test "cannot make a request interval when interval is too small" do
    assert {:error, :interval_too_small} == MaxInclusionRequestInterval.new(639)
  end

  test "cannot make a request interval when interval is too big" do
    assert {:error, :interval_too_big} == MaxInclusionRequestInterval.new(13000)
  end

  test "cannot make a request interval when interval step is not of 128 seconds" do
    assert {:error, :interval_step_invalid} == MaxInclusionRequestInterval.new(1300)
  end

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

  test "encode to binary when all is okay" do
    miri = %MaxInclusionRequestInterval{
      interval: 10368
    }

    expected_binary = <<0x04, 0x01, 0x4C>>

    assert {:ok, expected_binary} == MaxInclusionRequestInterval.to_binary(miri)
  end
end
