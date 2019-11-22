defmodule Grizzly.SmartStart.MetaExtension.BootstrappingModeTest do
  use ExUnit.Case, async: true

  alias Grizzly.SmartStart.MetaExtension.BootstrappingMode

  describe "create a BootstrappingMode.t()" do
    test "when mode is :security_2" do
      expected_mode = %BootstrappingMode{mode: :security_2}
      assert {:ok, expected_mode} == BootstrappingMode.new(:security_2)
    end

    test "when mode is :smart_start" do
      expected_mode = %BootstrappingMode{mode: :smart_start}
      assert {:ok, expected_mode} == BootstrappingMode.new(:smart_start)
    end

    test "when mode is invalid" do
      assert {:error, :invalid_mode} == BootstrappingMode.new(:asdf)
    end
  end

  describe "encoding BootstrappingMode.t()" do
    test "when mode is :security_2" do
      {:ok, mode} = BootstrappingMode.new(:security_2)
      expected_binary = <<0x6D, 0x01, 0x00>>

      assert {:ok, expected_binary} == BootstrappingMode.to_binary(mode)
    end

    test "when mode is :smart_start" do
      {:ok, mode} = BootstrappingMode.new(:smart_start)
      expected_binary = <<0x6D, 0x01, 0x01>>

      assert {:ok, expected_binary} == BootstrappingMode.to_binary(mode)
    end
  end

  describe "decoding BootstrappingMode.t()" do
    test "when mode is :security_2" do
      {:ok, expected_mode} = BootstrappingMode.new(:security_2)
      binary = <<0x6D, 0x01, 0x00>>

      assert {:ok, expected_mode} == BootstrappingMode.from_binary(binary)
    end

    test "when mode is :smart_start" do
      {:ok, expected_mode} = BootstrappingMode.new(:smart_start)
      binary = <<0x6D, 0x01, 0x01>>

      assert {:ok, expected_mode} == BootstrappingMode.from_binary(binary)
    end

    test "ensure critical bit is set" do
      binary = <<0x6C, 0x01, 0x00>>
      assert {:error, :critical_bit_not_set} == BootstrappingMode.from_binary(binary)
    end
  end
end
