defmodule Grizzly.CommandClass.MultiChannelAssociation.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.MultiChannelAssociation.Set
  alias Grizzly.Command.EncodeError

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: :fizz, endpoint: :buzz}
      ]

      {:ok, command} = Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x06)

      assert %Set{group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x06} == command
    end

    test "encodes correctly" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: 3, endpoint: 0}
      ]

      {:ok, command} =
        Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x06, retries: 0)

      binary =
        <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x8E, 0x01, 0x02, 0x02, 0x03, 0x00, 0x02, 0x02, 0x03,
          0x03, 0x03, 0x00>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "encodes incorrectly" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: :fizz, endpoint: :buzz}
      ]

      {:ok, command} = Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x06)

      error =
        EncodeError.new(
          {:invalid_argument_value, :endpoints, endpoints,
           Grizzly.CommandClass.MultiChannelAssociation.Set}
        )

      assert {:error, error} == Set.encode(command)
    end

    test "handles an ack response" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: :fizz, endpoint: :buzz}
      ]

      {:ok, command} = Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles a nack response" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: :fizz, endpoint: :buzz}
      ]

      {:ok, command} =
        Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x01, retries: 0)

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: :fizz, endpoint: :buzz}
      ]

      {:ok, command} = Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = Set.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: :fizz, endpoint: :buzz}
      ]

      {:ok, command} = Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = Set.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: :fizz, endpoint: :buzz}
      ]

      {:ok, command} = Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x06)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = Set.handle_response(command, packet)
    end

    test "handles responses" do
      endpoints = [
        %{node_id: 2, endpoint: 2},
        %{node_id: 3, endpoint: 3},
        %{node_id: :fizz, endpoint: :buzz}
      ]

      {:ok, command} = Set.init(group: 2, nodes: [2, 3], endpoints: endpoints, seq_number: 0x06)

      assert {:continue, _} = Set.handle_response(command, %{})
    end
  end
end
