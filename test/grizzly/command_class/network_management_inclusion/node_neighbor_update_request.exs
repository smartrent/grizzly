defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeNeighborUpdateRequest.Test do
  use ExUnit.Case, async: true

  alias Grizzly.{Node, Packet}
  alias Grizzly.CommandClass.NetworkManagementInclusion.NodeNeighborUpdateRequest

  describe "implements Grizzly.Command behaviour" do
    test "initializes the command" do
      assert {:ok, %NodeNeighborUpdateRequest{node_id: 6, seq_number: 0x01}} =
               NodeNeighborUpdateRequest.init(node_id: 0x06, seq_number: 0x01)
    end

    test "encodes correctly" do
      {:ok, command} = NodeNeighborUpdateRequest.init(node_id: 0x06, seq_number: 0x09)
      binary = <<35, 2, 128, 208, 9, 0, 0, 3, 2, 0, 0x34, 0x0B, 0x09, 0x06>>

      assert {:ok, binary} == NodeNeighborUpdateRequest.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = NodeNeighborUpdateRequest.init(nodee_id: 0x06, seq_number: 0xA0)
      packet = Packet.new(seq_number: 0xA0, types: [:ack_response])

      assert {:continue, ^command} = NodeNeighborUpdateRequest.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = NodeNeighborUpdateRequest.init(node_id: 0x06, seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} =
               NodeNeighborUpdateRequest.handle_response(command, packet)
    end

    test "handle node add status report response" do
      report = %{
        command: :node_neighbor_update_status,
        status: :done
      }

      packet = Packet.new(body: report)

      {:ok, command} = NodeNeighborUpdateRequest.init(node_id: 0x06, seq_number: 0x14)
      assert {:done, {:ok, :done}} = NodeAdd.handle_response(command, packet)
    end

    test "handle respones" do
      {:ok, command} = NodeNeighborUpdateRequest.init(node_id: 0x06, seq_number: 0x10)

      assert {:continue, ^command} =
               NodeNeighborUpdateRequest.handle_response(command, %{command: :llama})
    end
  end
end
