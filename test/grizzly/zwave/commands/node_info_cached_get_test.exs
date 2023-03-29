defmodule Grizzly.ZWave.Commands.NodeInfoCachedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeInfoCachedGet

  test "ensure correct byte" do
    {:ok, cmd} = NodeInfoCachedGet.new()

    assert cmd.command_byte == 0x03
  end

  test "ensure correct name" do
    {:ok, cmd} = NodeInfoCachedGet.new()

    assert cmd.name == :node_info_cached_get
  end

  describe "encoding" do
    test "version 1-3 - 8 bit node id" do
      {:ok, cmd} = NodeInfoCachedGet.new(seq_number: 0x01, node_id: 0x04, max_age: 0x03)

      expected_bin = <<0x01, 0x03, 0x04>>

      for v <- 1..3 do
        assert NodeInfoCachedGet.encode_params(cmd, command_class_version: v) == expected_bin
      end
    end

    test "version 4 - 8 bit node id" do
      {:ok, cmd} = NodeInfoCachedGet.new(seq_number: 0x01, node_id: 0x04, max_age: 0x03)

      expected_bin = <<0x01, 0x03, 0x04, 0x04::16>>

      assert NodeInfoCachedGet.encode_params(cmd) == expected_bin
    end

    test "version 4 - 16 bit node id" do
      {:ok, cmd} = NodeInfoCachedGet.new(seq_number: 0x01, node_id: 0x04AA, max_age: 0x03)

      expected_bin = <<0x01, 0x03, 0xFF, 0x04, 0xAA>>

      assert NodeInfoCachedGet.encode_params(cmd) == expected_bin
    end
  end

  describe "decoding" do
    test "version 1-3 - 8 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x07, max_age: 0x05]
      {:ok, params} = NodeInfoCachedGet.decode_params(<<0x01, 0x05, 0x07>>)

      assert_params(expected_params, params)
    end

    test "version 4 - 8 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x07, max_age: 0x05]
      {:ok, params} = NodeInfoCachedGet.decode_params(<<0x01, 0x05, 0x07, 0x00, 0x00>>)

      assert_params(expected_params, params)
    end

    test "version 4 - 16 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x07A1, max_age: 0x05]
      {:ok, params} = NodeInfoCachedGet.decode_params(<<0x01, 0x05, 0xFF, 0x07, 0xA1>>)

      assert_params(expected_params, params)
    end
  end

  defp assert_params(expected_params, params) do
    for {param, value} <- expected_params do
      assert params[param] == value
    end
  end
end
