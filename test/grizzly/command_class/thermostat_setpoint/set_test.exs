defmodule Grizzly.CommandClass.ThermostatSetpoint.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ThermostatSetpoint.Set

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} = Set.init(type: :cooling)

      assert %Set{type: :cooling} == command
    end

    test "encodes correctly" do
      {:ok, command} = Set.init(type: :cooling, value: 78, seq_number: 0x06)
      binary = <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x43, 0x01, 0x02, 0x09, 78>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} = Set.init(type: :cooling, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} = Set.init(type: :cooling, seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Set.init(type: :cooling, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, %Set{}} = Set.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Set.init(type: :cooling)

      assert {:continue, _} = Set.handle_response(command, %{})
    end
  end
end
