defmodule Grizzly.CommandClass.NodeProvisioning.MetaExtension.SmartStartInclusionSettingTest do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.NodeProvisioning.MetaExtension.SmartStartInclusionSetting

  test "encode pending setting" do
    setting = %SmartStartInclusionSetting{setting: :pending}

    expected_binary = <<0x69, 0x01, 0x00>>

    assert {:ok, expected_binary} == SmartStartInclusionSetting.to_binary(setting)
  end

  test "encode passive setting" do
    setting = %SmartStartInclusionSetting{setting: :passive}

    expected_binary = <<0x69, 0x01, 0x02>>

    assert {:ok, expected_binary} == SmartStartInclusionSetting.to_binary(setting)
  end

  test "encode ignored setting" do
    setting = %SmartStartInclusionSetting{setting: :ignored}

    expected_binary = <<0x69, 0x01, 0x03>>

    assert {:ok, expected_binary} == SmartStartInclusionSetting.to_binary(setting)
  end

  test "handles bad setting" do
    bad_setting = %SmartStartInclusionSetting{setting: :bad}

    assert {:error, :invalid_setting} == SmartStartInclusionSetting.to_binary(bad_setting)
  end

  test "decodes pending setting" do
    binary = <<0x69, 0x01, 0x00>>

    expected_setting = %SmartStartInclusionSetting{setting: :pending}

    assert {:ok, expected_setting} == SmartStartInclusionSetting.from_binary(binary)
  end

  test "decodes passive setting" do
    binary = <<0x69, 0x01, 0x02>>

    expected_setting = %SmartStartInclusionSetting{setting: :passive}

    assert {:ok, expected_setting} == SmartStartInclusionSetting.from_binary(binary)
  end

  test "decodes ignored setting" do
    binary = <<0x69, 0x01, 0x03>>

    expected_setting = %SmartStartInclusionSetting{setting: :ignored}

    assert {:ok, expected_setting} == SmartStartInclusionSetting.from_binary(binary)
  end

  test "hanlding decoding bad setting" do
    binary = <<0x69, 0x01, 0x01>>

    assert {:error, :invalid_setting} == SmartStartInclusionSetting.from_binary(binary)
  end
end
