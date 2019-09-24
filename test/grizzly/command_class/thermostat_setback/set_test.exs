defmodule Grizzly.CommandClass.ThermostatSetback.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ThermostatSetback.Set
  alias Grizzly.Command.EncodeError

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} = Set.init(type: :temporary_override, state: -128)

      assert %Set{type: :temporary_override, state: -128} == command
    end

    test "encodes correctly" do
      {:ok, command} = Set.init(type: :temporary_override, state: -128, seq_number: 0x06)

      binary =
        <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x47, 0x01, 0x00::size(6), 0x01::size(2), 0x80>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = Set.init(type: :blue, state: -128, seq_number: 0x06)

      error = EncodeError.new({:invalid_argument_value, :type, :blue, Set})

      assert {:error, error} == Set.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} = Set.init(type: :no_overriding, state: 0, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} = Set.init(type: :no_overriding, state: 0, seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Set.init(type: :no_overriding, state: 0, seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, %Set{}} = Set.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Set.init(type: :no_overriding, state: 0)

      assert {:continue, _} = Set.handle_response(command, %{})
    end
  end
end
