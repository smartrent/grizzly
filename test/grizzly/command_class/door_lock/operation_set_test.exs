defmodule Grizzly.CommandClass.DoorLock.OperationSet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.DoorLock.OperationSet

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, %OperationSet{mode: :unsecured}} == OperationSet.init(mode: :unsecured)
    end

    test "encodes correctly" do
      {:ok, command} = OperationSet.init(mode: :secured, seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x62, 0x01, 0xFF>>

      assert {:ok, binary} == OperationSet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = OperationSet.init(mode: :unsecured, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == OperationSet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = OperationSet.init(mode: :unsecured, seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == OperationSet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = OperationSet.init(mode: :unsecured, seq_number: 0x14)
      packet = Packet.new(seq_number: 0x14, types: [:nack_response])

      assert {:retry, _command} = OperationSet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = OperationSet.init(mode: :secured)
      assert {:continue, ^command} = OperationSet.handle_response(command, %{})
    end
  end
end
