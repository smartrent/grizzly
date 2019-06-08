defmodule Grizzly.CommandClass.DoorLock.OperationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.DoorLock.OperationGet

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, %OperationGet{}} = OperationGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = OperationGet.init(seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x62, 0x02>>
      assert {:ok, binary} == OperationGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = OperationGet.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])
      assert {:continue, ^command} = OperationGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = OperationGet.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == OperationGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = OperationGet.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:retry, _command} = OperationGet.handle_response(command, packet)
    end

    test "handles door lock report" do
      report = %{command_class: :door_lock, command: :report, value: :lock}
      packet = Packet.new(body: report)
      {:ok, command} = OperationGet.init([])

      assert {:done, {:ok, :lock}} == OperationGet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = OperationGet.init([])

      assert {:continue, ^command} = OperationGet.handle_response(command, %{foo: :bar})
    end
  end
end
