defmodule Grizzly.CommandClass.NetworkManagementInclusion.FailedNodeRemove.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementInclusion.FailedNodeRemove
  alias Grizzly.Command.EncodeError

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} = FailedNodeRemove.init(node_id: 0x02)

      assert %FailedNodeRemove{node_id: 0x02} == command
    end

    test "encodes correctly" do
      {:ok, command} = FailedNodeRemove.init(node_id: 0x02, seq_number: 0x06)
      binary = <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x34, 0x07, 0x06, 0x02>>

      assert {:ok, binary} == FailedNodeRemove.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = FailedNodeRemove.init(node_id: :blue, seq_number: 0x06)

      error = EncodeError.new({:invalid_argument_value, :node_id, :blue, FailedNodeRemove})

      assert {:error, error} == FailedNodeRemove.encode(command)
    end

    test "handles status report responses" do
      report = %{
        command_class: :network_management_inclusion,
        command: :failed_node_remove_status,
        value: %{node_id: 0x02, status: :done}
      }

      {:ok, command} = FailedNodeRemove.init(node_id: 2)
      packet = Packet.new(body: report)

      assert {:done, {:ok, %{node_id: 0x02, status: :done}}} ==
               FailedNodeRemove.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} = FailedNodeRemove.init(node_id: 0x02, seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               FailedNodeRemove.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = FailedNodeRemove.init(node_id: 0x02, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = FailedNodeRemove.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = FailedNodeRemove.init(node_id: 0x02, seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = FailedNodeRemove.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = FailedNodeRemove.init(node_id: 0x02)

      assert {:continue, _} = FailedNodeRemove.handle_response(command, %{})
    end
  end
end
