defmodule Grizzly.CommandClass.Version.CommandClassGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Version
  alias Grizzly.CommandClass.Version.CommandClassGet
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, %CommandClassGet{}} = CommandClassGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = CommandClassGet.init(seq_number: 0x05, command_class: :switch_binary)

      binary = <<35, 2, 128, 208, 5, 0, 0, 3, 2, 0, 0x86, 0x13, 0x25>>

      assert {:ok, binary} == CommandClassGet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = CommandClassGet.init(command_class: :fizzbuzz, seq_number: 0x06)

      error =
        EncodeError.new({:invalid_argument_value, :command_class, :fizzbuzz, CommandClassGet})

      assert {:error, error} == CommandClassGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = CommandClassGet.init(seq_number: 0x05, command_class: :switch_binary)
      packet = Packet.new(seq_number: 0x05, types: [:ack_response])

      assert {:continue, ^command} = CommandClassGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} =
        CommandClassGet.init(seq_number: 0x05, command_class: :switch_binary, retries: 0)

      packet = Packet.new(seq_number: 0x05, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == CommandClassGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = CommandClassGet.init(seq_number: 0x05, command_class: :switch_binary)
      packet = Packet.new(seq_number: 0x05, types: [:nack_response])

      assert {:retry, %CommandClassGet{retries: 1}} =
               CommandClassGet.handle_response(command, packet)
    end

    test "handles command class version report response" do
      report = %{command_class: Version, command: :report, value: 1}
      packet = Packet.new(body: report)
      {:ok, command} = CommandClassGet.init(seq_number: 0x05, command_class: :switch_binary)

      assert {:done, {:ok, 1}} == CommandClassGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = CommandClassGet.init(seq_number: 0x01, command_class: :switch_binary)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = CommandClassGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = CommandClassGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = CommandClassGet.handle_response(command, packet)
    end

    test "handles other response" do
      {:ok, command} = CommandClassGet.init(seq_number: 0x05, command_class: :switch_binary)

      assert {:continue, ^command} =
               CommandClassGet.handle_response(command, %{command: :ice_cream})
    end
  end
end
