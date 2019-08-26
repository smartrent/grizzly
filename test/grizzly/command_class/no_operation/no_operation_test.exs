defmodule Grizzly.CommandClass.NetworkManagementInstallationMaintenance.NoOperationTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NoOperation

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %NoOperation{}} = NoOperation.init([])
    end

    test "encodes correctly" do
      {:ok, command} = NoOperation.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x00>>

      assert {:ok, binary} == NoOperation.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = NoOperation.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:done, :ok} = NoOperation.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = NoOperation.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               NoOperation.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = NoOperation.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = NoOperation.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = NoOperation.init(seq_number: 0x01, command_class: :switch_binary)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = NoOperation.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = NoOperation.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = NoOperation.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = NoOperation.init([])

      assert {:continue, %NoOperation{}} ==
               NoOperation.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
