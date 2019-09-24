defmodule Grizzly.CommandClass.NetworkManagmentProxy.NodeInfoCache.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementProxy.NodeInfoCache
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, %NodeInfoCache{}} = NodeInfoCache.init([])
    end

    test "encodes correctly" do
      {:ok, command} = NodeInfoCache.init(cached_minutes_passed: 15, node_id: 1, seq_number: 0x01)
      binary = <<35, 2, 128, 208, 1, 0, 0, 3, 2, 0, 0x52, 0x03, 0x01, 15, 1>>
      assert {:ok, binary} == NodeInfoCache.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} =
        NodeInfoCache.init(cached_minutes_passed: 0xFFFFFFFF1, node_id: 1, seq_number: 0x06)

      # More than 4 bytes
      error =
        EncodeError.new(
          {:invalid_argument_value, :cached_minutes_passed, 0xFFFFFFFF1, NodeInfoCache}
        )

      assert {:error, error} == NodeInfoCache.encode(command)
    end

    test "handles ack_responses" do
      {:ok, command} = NodeInfoCache.init(seq_number: 0x04)
      packet = Packet.new(seq_number: 0x04, types: [:ack_response])
      assert {:continue, ^command} = NodeInfoCache.handle_response(command, packet)
    end

    test "handles nack responses" do
      {:ok, command} = NodeInfoCache.init(seq_number: 0x04, retries: 0)
      packet = Packet.new(seq_number: 0x04, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == NodeInfoCache.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = NodeInfoCache.init(seq_number: 0x04)
      packet = Packet.new(seq_number: 0x04, types: [:nack_response])

      assert {:retry, %NodeInfoCache{retries: 1}} = NodeInfoCache.handle_response(command, packet)
    end

    test "handles node info cache report" do
      report = %{command: :node_info_cache_report, report: :report}
      {:ok, command} = NodeInfoCache.init(seq_number: 0x04)
      packet = Packet.new(body: report)

      assert {:done, {:ok, :report}} = NodeInfoCache.handle_response(command, packet)
    end

    test "handles other responses" do
      report = %{command: :foo}
      {:ok, command} = NodeInfoCache.init([])

      assert {:continue, ^command} = NodeInfoCache.handle_response(command, report)
    end
  end
end
