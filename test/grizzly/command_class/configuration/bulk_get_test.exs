defmodule Grizzly.CommandClass.Configuration.BulkGet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Configuration.BulkGet
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %BulkGet{}} == BulkGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = BulkGet.init(seq_number: 10, start: 85, number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x70, 0x08, 0, 85, 10>>

      assert {:ok, binary} == BulkGet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = BulkGet.init(start: 1, number: :blue, seq_number: 0x06)

      error =
        EncodeError.new(
          {:invalid_argument_value, :number, :blue, Grizzly.CommandClass.Configuration.BulkGet}
        )

      assert {:error, error} == BulkGet.encode(command)
    end

    test "handles nack respones" do
      {:ok, command} = BulkGet.init(seq_number: 0x03, retries: 0)
      packet = Packet.new(seq_number: 0x03, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == BulkGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = BulkGet.init(seq_number: 0x03)
      packet = Packet.new(seq_number: 0x03, types: [:nack_response])

      assert {:retry, %BulkGet{retries: 1}} = BulkGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = BulkGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = BulkGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = BulkGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = BulkGet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = BulkGet.init([])
      assert {:continue, %BulkGet{}} = BulkGet.handle_response(command, %{command_class: :foo})
    end
  end
end
