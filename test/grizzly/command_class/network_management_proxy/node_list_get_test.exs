defmodule Grizzly.CommandClass.NetworkManagementProxy.NodeListGet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementProxy.NodeListGet

  describe "implements Grizzly.Command behaviour" do
    test "initializes with command state" do
      assert {:ok, _} = NodeListGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = NodeListGet.init(seq_number: 0x05)
      binary = <<35, 2, 128, 208, 5, 0, 0, 3, 2, 0, 0x52, 0x01, 0x05>>
      assert {:ok, binary} == NodeListGet.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = NodeListGet.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x05, types: [:ack_response])
      assert {:continue, ^command} = NodeListGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = NodeListGet.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == NodeListGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = NodeListGet.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:retry, %NodeListGet{retries: 1}} = NodeListGet.handle_response(command, packet)
    end

    test "handles node list report" do
      report = %{
        command_class: :network_management_proxy,
        command: :node_list_report,
        node_list: [1, 2]
      }

      {:ok, command} = NodeListGet.init(seq_number: 0x10)
      packet = Packet.new(body: report)

      assert {:done, {:ok, [1, 2]}} == NodeListGet.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = NodeListGet.init([])
      assert {:continue, ^command} = NodeListGet.handle_response(command, %{command: :food})
    end
  end
end
