defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeAddDSKSet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementInclusion.NodeAddDSKSet

  test "initializes the command options" do
    opts = [
      seq_number: 0x01,
      accept: true,
      input_dsk_length: 0
    ]

    assert {:ok, %NodeAddDSKSet{}} = NodeAddDSKSet.init(opts)
  end

  describe "encoding the command" do
    test "encodes when no DSK is provided (Unauthenticated S2)" do
      opts = [
        seq_number: 0x01,
        accept: true,
        input_dsk_length: 0
      ]

      {:ok, command} = NodeAddDSKSet.init(opts)
      expected_binary = Packet.header(0x01) <> <<0x34, 0x14, 0x01, 0x80, 0x00>>

      assert {:ok, expected_binary} == NodeAddDSKSet.encode(command)
    end

    test "encodes when an DSK is provided" do
      opts = [
        seq_number: 0x01,
        accept: true,
        input_dsk_length: 2,
        input_dsk: 33243
      ]

      {:ok, command} = NodeAddDSKSet.init(opts)
      expected_binary = Packet.header(0x01) <> <<0x34, 0x14, 0x01, 0x82, 0x81, 0xDB>>

      assert {:ok, expected_binary} == NodeAddDSKSet.encode(command)
    end
  end
end
