defmodule Grizzly.CommandClass.NetworkManagementBasic.DefaultSet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementBasic.DefaultSet

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, _} = DefaultSet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = DefaultSet.init(seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x4D, 0x06, 10>>

      assert {:ok, binary} == DefaultSet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = DefaultSet.init(seq_number: 0x04)
      packet = Packet.new(seq_number: 0x04, types: [:ack_response])

      assert {:continue, ^command} = DefaultSet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = DefaultSet.init(seq_number: 0x07, retries: 0)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == DefaultSet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = DefaultSet.init(seq_number: 0x07)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:retry, %DefaultSet{retries: 1}} = DefaultSet.handle_response(command, packet)
    end

    test "handles default set complete response" do
      report = %{command: :default_set_complete, status: :done}
      packet = Packet.new(body: report)
      {:ok, command} = DefaultSet.init(seq_number: 0x01)

      assert {:done, {:ok, :done}} == DefaultSet.handle_response(command, packet)
    end
  end
end
