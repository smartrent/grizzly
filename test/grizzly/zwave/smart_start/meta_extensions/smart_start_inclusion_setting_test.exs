defmodule Grizzly.ZWave.SmartStart.MetaExtension.SmartStartInclusionSettingTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.SmartStart.MetaExtension.SmartStartInclusionSetting

  test "creates a new setting pending" do
    expected_setting = %SmartStartInclusionSetting{setting: :pending}
    assert {:ok, expected_setting} == SmartStartInclusionSetting.new(:pending)
  end

  test "creates a new setting passive" do
    expected_setting = %SmartStartInclusionSetting{setting: :passive}
    assert {:ok, expected_setting} == SmartStartInclusionSetting.new(:passive)
  end

  test "creates a new setting ignored" do
    expected_setting = %SmartStartInclusionSetting{setting: :ignored}
    assert {:ok, expected_setting} == SmartStartInclusionSetting.new(:ignored)
  end

  test "does not create a new setting when the setting is invalid" do
    assert {:error, :invalid_setting} == SmartStartInclusionSetting.new(:blue)
  end

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

  test "handles decoding bad setting" do
    binary = <<0x69, 0x01, 0x01>>

    assert {:error, :invalid_setting} == SmartStartInclusionSetting.from_binary(binary)
  end
end
