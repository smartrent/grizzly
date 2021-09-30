defmodule Grizzly.ZWave.NodeIdTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.NodeId

  test "encodes a node id" do
    assert NodeId.encode(0x01) == <<0x01>>
  end

  describe "encoding a node id with extended node id format" do
    test "with 8 bit node id" do
      assert NodeId.encode_extended(0x08) == <<0x08, 0x08::16>>
    end

    test "with 16 bit node id" do
      assert NodeId.encode_extended(0x3010) == <<0xFF, 0x30, 0x10>>
    end
  end

  describe "parsing a node id binary" do
    test "with 8 bit node id without extended format" do
      assert NodeId.parse(<<0x08>>) == 0x08
    end

    test "with 8 bit node id with extended format" do
      assert NodeId.parse(<<0x08, 0x00::16>>) == 0x08
    end

    test "with 16 bit node id" do
      assert NodeId.parse(<<0xFF, 0x40, 0x10>>) == 0x4010
    end

    test "with delimiter of 3 bytes and 8 bit node id" do
      bin = <<0x08, 0x01, 0x02, 0x03, 0x00, 0x08>>

      assert NodeId.parse(bin, delimiter_size: 3) == 0x08
    end

    test "with delimiter of 3 bytes and 16 bit node id" do
      bin = <<0xFF, 0x01, 0x02, 0x03, 0x10, 0x01>>

      assert NodeId.parse(bin, delimiter_size: 3) == 0x1001
    end

    test "with delimiter of 3 bytes but no 16 bit node id" do
      bin = <<0x10, 0x01, 0x02, 0x03>>

      assert NodeId.parse(bin, delimiter_size: 3) == 0x10
    end

    test "with extra bytes after the 16 bit node id" do
      bin = <<0xFF, 0x01, 0x00, 0x01, 0x02, 0x03>>

      assert NodeId.parse(bin) == 0x0100
    end
  end
end
