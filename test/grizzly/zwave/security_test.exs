defmodule Grizzly.ZWave.SecurityTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Security

  describe "decoding a byte of granted keys to a list of keys" do
    test "Unauthenticated only" do
      byte = 0x01
      assert [:s2_unauthenticated] == Security.byte_to_keys(byte)
    end

    test "Unauthenticated and authenticated" do
      # this is 3 but want to make sure the bits are relected as they will be in real life
      byte = 0b11
      assert [:s2_authenticated, :s2_unauthenticated] == Security.byte_to_keys(byte)
    end

    test "s0 only" do
      # this is 128 but reflecting bits as in Z-Wave docs
      byte = 0b1000_0000
      assert [:s0] == Security.byte_to_keys(byte)
    end

    test "access control only" do
      # reflecting bits as documented in Z-Wave docs
      byte = 0b100
      assert [:s2_access_control] == Security.byte_to_keys(byte)
    end

    test "all s2 groups" do
      # reflecting bits as documented in Z-Wave docs
      byte = 0b111

      assert [:s2_access_control, :s2_authenticated, :s2_unauthenticated] ==
               Security.byte_to_keys(byte)
    end

    test "authenticated and access_control" do
      byte = 0b110
      assert [:s2_access_control, :s2_authenticated] == Security.byte_to_keys(byte)
    end
  end

  describe "get highest security level" do
    test "handles insecure devices" do
      assert :none == Security.get_highest_level([])
    end

    test "handles S0 devices" do
      assert :s0 == Security.get_highest_level([:s0])
    end

    test "handles authenticated devices that also support unauthenticated" do
      assert :s2_authenticated ==
               Security.get_highest_level([:s2_authenticated, :s2_unauthenticated])

      assert :s2_authenticated ==
               Security.get_highest_level([:s2_unauthenticated, :s2_authenticated])
    end

    test "handles unauthenticated devices" do
      assert :s2_unauthenticated == Security.get_highest_level([:s2_unauthenticated])
    end
  end
end
