defmodule Grizzly.CommandClass.ThermostatMode.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ThermostatMode.Set
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, %Set{mode: :cool}} == Set.init(mode: :cool)
    end

    test "encodes correctly" do
      {:ok, command} = Set.init(mode: :cool, seq_number: 0x01)
      binary = <<35, 2, 128, 208, 1, 0, 0, 3, 2, 0, 0x40, 0x01, 0x02>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = Set.init(mode: :blue, seq_number: 0x06)

      error = EncodeError.new({:invalid_argument_value, :mode, :blue, Set})

      assert {:error, error} == Set.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Set.init(mode: :cool, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Set.init(mode: :cool, seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Set.init(mode: :cool, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:retry, %Set{}} = Set.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Set.init(mode: :cool)
      assert {:continue, ^command} = Set.handle_response(command, %{})
    end
  end
end
