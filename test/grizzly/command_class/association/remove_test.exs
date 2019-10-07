defmodule Grizzly.CommandClass.Association.Remove.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Association.Remove
  alias Grizzly.Command.EncodeError

  describe "implements command behaviour" do
    test "initializes command state" do
      assert {:ok, %Remove{group: 1, nodes: [0x03, 0x05]}} == Remove.init(group: 1, nodes: [3, 5])
    end

    test "encodes correctly" do
      {:ok, command} = Remove.init(group: 1, nodes: [3, 5], seq_number: 0x01)
      packet = <<35, 2, 128, 208, 1, 0, 0, 3, 2, 0, 0x85, 0x04, 0x01, 0x03, 0x05>>

      assert {:ok, packet} == Remove.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = Remove.init(group: 300, nodes: [4, "bla"], seq_number: 0x01)

      error =
        EncodeError.new(
          {:invalid_argument_value, :group, 300, Grizzly.CommandClass.Association.Remove}
        )

      assert {:error, error} == Remove.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Remove.init(group: 1, nodes: [3, 6], seq_number: 0x04)
      packet = Packet.new(seq_number: 0x04, types: [:ack_response])
      assert {:done, :ok} == Remove.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Remove.init(group: 4, nodes: [0x91, 0x16], seq_number: 0x04, retries: 0)
      packet = Packet.new(seq_number: 0x04, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == Remove.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Remove.init(group: 4, nodes: [0x91, 0x16], seq_number: 0x04)
      packet = Packet.new(seq_number: 0x04, types: [:nack_response])
      assert {:retry, %Remove{}} = Remove.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = Remove.init(seq_number: 0x01, group: 1, nodes: [0x01, 0x02])

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = Remove.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = Remove.init(seq_number: 0x01, group: 1, nodes: [0x01, 0x02])

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = Remove.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = Remove.init(group: 1, nodes: [0xEF, 0x10])
      assert {:continue, ^command} = Remove.handle_response(command, %{})
    end
  end
end
