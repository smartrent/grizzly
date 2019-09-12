defmodule Grizzly.CommandClass.Configuration.Set.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Configuration.Set
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %Set{}} = Set.init([])
    end

    test "encodes for list of args" do
      {:ok, command} =
        Set.init(
          config_param: 85,
          size: 1,
          arg: [0x01],
          seq_number: 10
        )

      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x70, 0x04, 85, 0x01, 0x01>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "encodes incorrectly for list of args" do
      {:ok, command} = Set.init(size: 2, config_param: 1, arg: [3, :blue], seq_number: 0x06)

      error =
        EncodeError.new(
          {:invalid_argument_value, :arg, [3, :blue], Grizzly.CommandClass.Configuration.Set}
        )

      assert {:error, error} == Set.encode(command)
    end

    test "encodes for when arg is an integer" do
      {:ok, command} =
        Set.init(
          config_param: 85,
          size: 1,
          arg: 214,
          seq_number: 10
        )

      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x70, 0x04, 85, 0x01, 214>>

      assert {:ok, binary} == Set.encode(command)
    end

    test "encodes incorrectly arg is an integer" do
      {:ok, command} = Set.init(size: 2, config_param: 1, arg: :blue, seq_number: 0x06)

      error =
        EncodeError.new(
          {:invalid_argument_value, :arg, :blue, Grizzly.CommandClass.Configuration.Set}
        )

      assert {:error, error} == Set.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Set.init(seq_number: 0x08)
      packet = Packet.new(seq_number: 0x08, types: [:ack_response])
      assert {:done, :ok} == Set.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Set.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == Set.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Set.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])
      assert {:retry, %Set{retries: 1}} = Set.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = Set.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = Set.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = Set.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = Set.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = Set.init([])

      assert {:continue, ^command} = Set.handle_response(command, %{code: 1})
    end
  end
end
