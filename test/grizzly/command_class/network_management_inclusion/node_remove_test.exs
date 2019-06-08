defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeRemove.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementInclusion.NodeRemove

  describe "implements the Grizzly.CommandClass behaviour" do
    test "initializes command" do
      assert {:ok, %NodeRemove{mode: :any, seq_number: 0x01}} == NodeRemove.init(seq_number: 0x01)
    end

    test "encodes correctly" do
      {:ok, command} = NodeRemove.init(seq_number: 0x12)
      binary = <<35, 2, 128, 208, 18, 0, 0, 3, 2, 0, 0x34, 0x03, 0x12, 0x00, 0x01>>
      assert {:ok, binary} == NodeRemove.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = NodeRemove.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])
      assert {:continue, ^command} = NodeRemove.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = NodeRemove.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:done, {:error, :nack_response}} = NodeRemove.handle_response(command, packet)
    end

    test "handles node removed failed" do
      report = %{command: :node_remove_status, status: :failed}
      {:ok, command} = NodeRemove.init(seq_number: 0x12)
      packet = Packet.new(body: report, seq_number: 0x012)

      assert {:done, {:error, :node_remove_failed}} == NodeRemove.handle_response(command, packet)
    end

    test "handles node removed done" do
      report = %{command: :node_remove_status, status: :done, node_id: 10}
      {:ok, command} = NodeRemove.init(seq_number: 0x01)
      packet = Packet.new(body: report)

      assert {:done, {:ok, 10}} == NodeRemove.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = NodeRemove.init(seq_number: 15)

      assert {:continue, ^command} = NodeRemove.handle_response(command, %{commnd: :report})
    end
  end
end
