defmodule Grizzly.CommandClass.SwitchBinary.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.SwitchBinary.Set
  alias Grizzly.Command.EncodeError

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} = Set.init(value: :on)

      assert %Set{value: :on} == command
    end

    test "encodes correctly" do
      {:ok, command} = Set.init(value: :off, seq_number: 0x06)
      binary = <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x25, 0x01, 0x00>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = Set.init(value: :blue, seq_number: 0x06)

      error =
        EncodeError.new(
          {:invalid_argument_value, :value, :blue, Grizzly.CommandClass.SwitchBinary.Set}
        )

      assert {:error, error} == Set.encode(command)
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

    test "handles responses" do
      {:ok, command} = Set.init(value: :on)

      assert {:continue, _} = Set.handle_response(command, %{})
    end
  end
end
