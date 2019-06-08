defmodule Grizzly.CommandClass.Basic.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Basic.Set

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} = Set.init(value: :on)

      assert %Set{value: :on} == command
    end

    test "encodes correctly" do
      {:ok, command} = Set.init(value: :off, seq_number: 0x06)
      binary = <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x20, 0x01, 0x00>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} = Set.init(value: :on, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} = Set.init(value: :off, seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Set.init(value: :off, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = Set.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = Set.init(value: :off, seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = Set.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = Set.init(value: :off, seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = Set.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Set.init(value: :on)

      assert {:continue, _} = Set.handle_response(command, %{})
    end
  end
end
