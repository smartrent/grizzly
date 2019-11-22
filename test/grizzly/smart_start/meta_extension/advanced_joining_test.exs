defmodule Grizzly.SmartStart.MetaExtension.AdvancedJoiningTest do
  use ExUnit.Case, async: true

  alias Grizzly.SmartStart.MetaExtension.AdvancedJoining

  describe "creating a AdvancedJoining.t()" do
    test "when all is okay" do
      keys = [:s2_unauthenticated]
      expected_joining = %AdvancedJoining{keys: keys}
      assert {:ok, expected_joining} == AdvancedJoining.new(keys)
    end

    test "when no keys are provided" do
      assert {:error, :empty_keys} == AdvancedJoining.new([])
    end

    test "when invalid keys are provided" do
      assert {:error, :invalid_keys} == AdvancedJoining.new([:red, :green, :blue])
    end
  end

  describe "encoding to binary" do
    test "s2_unauthenticated key only" do
      {:ok, joining} = AdvancedJoining.new([:s2_unauthenticated])

      expected_binary = <<0x6B, 0x01, 0x01>>

      assert {:ok, expected_binary} == AdvancedJoining.to_binary(joining)
    end

    test "s2_authenticated key only" do
      {:ok, joining} = AdvancedJoining.new([:s2_authenticated])

      expected_binary = <<0x6B, 0x01, 0x02>>

      assert {:ok, expected_binary} == AdvancedJoining.to_binary(joining)
    end

    test "s2_access_control key only" do
      {:ok, joining} = AdvancedJoining.new([:s2_access_control])

      expected_binary = <<0x6B, 0x01, 0x04>>

      assert {:ok, expected_binary} == AdvancedJoining.to_binary(joining)
    end

    test "s0 key only" do
      {:ok, joining} = AdvancedJoining.new([:s0])

      expected_binary = <<0x6B, 0x01, 0x40>>

      assert {:ok, expected_binary} == AdvancedJoining.to_binary(joining)
    end

    test "2 keys" do
      {:ok, joining} = AdvancedJoining.new([:s0, :s2_unauthenticated])

      expected_binary = <<0x6B, 0x01, 0x41>>

      assert {:ok, expected_binary} == AdvancedJoining.to_binary(joining)
    end

    test "all keys" do
      {:ok, joining} =
        AdvancedJoining.new([:s0, :s2_unauthenticated, :s2_authenticated, :s2_access_control])

      expected_binary = <<0x6B, 0x01, 0x47>>

      assert {:ok, expected_binary} == AdvancedJoining.to_binary(joining)
    end
  end

  describe "decoding from binary" do
    test "s2_unauthenticated key only" do
      binary = <<0x6B, 0x01, 0x01>>

      {:ok, expected_joining} = AdvancedJoining.new([:s2_unauthenticated])

      assert {:ok, expected_joining} == AdvancedJoining.from_binary(binary)
    end

    test "s2_authenticated key only" do
      binary = <<0x6B, 0x01, 0x02>>
      {:ok, expected_joining} = AdvancedJoining.new([:s2_authenticated])

      assert {:ok, expected_joining} == AdvancedJoining.from_binary(binary)
    end

    test "s2_access_control key only" do
      binary = <<0x6B, 0x01, 0x04>>

      {:ok, expected_joining} = AdvancedJoining.new([:s2_access_control])

      assert {:ok, expected_joining} == AdvancedJoining.from_binary(binary)
    end

    test "s0 key only" do
      binary = <<0x6B, 0x01, 0x40>>

      {:ok, expected_joining} = AdvancedJoining.new([:s0])

      assert {:ok, expected_joining} == AdvancedJoining.from_binary(binary)
    end

    test "2 keys" do
      binary = <<0x6B, 0x01, 0x41>>
      {:ok, expected_joining} = AdvancedJoining.new([:s0, :s2_unauthenticated])

      assert {:ok, expected_joining} == AdvancedJoining.from_binary(binary)
    end

    test "all keys" do
      binary = <<0x6B, 0x01, 0x47>>

      {:ok, expected_joining} =
        AdvancedJoining.new([:s0, :s2_access_control, :s2_authenticated, :s2_unauthenticated])

      assert {:ok, expected_joining} == AdvancedJoining.from_binary(binary)
    end
  end
end
