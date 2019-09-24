defmodule Grizzly.CommandClass.WakeUp.IntervalSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.WakeUp.IntervalSet
  alias Grizzly.Command.EncodeError

  test "initializes correctly" do
    assert {:ok, %IntervalSet{}} = IntervalSet.init(seconds: 10, node_id: 1)
  end

  test "encodes correctly" do
    {:ok, command} = IntervalSet.init(seconds: 1, seq_number: 0x01, node_id: 0x01)

    binary = <<35, 2, 128, 208, 1, 0, 0, 3, 2, 0, 0x84, 0x04, 0x00, 0x00, 0x01, 0x01>>

    assert {:ok, binary} == IntervalSet.encode(command)
  end

  test "encodes incorrectly" do
    {:ok, command} = IntervalSet.init(seconds: :blue, seq_number: 0x01, node_id: 0x01)

    error = EncodeError.new({:invalid_argument_value, :seconds, :blue, IntervalSet})

    assert {:error, error} == IntervalSet.encode(command)
  end

  test "handles ack response" do
    {:ok, command} = IntervalSet.init(seq_number: 0x01, seconds: 0x01, node_id: 0x01)
    packet = Packet.new(seq_number: 0x01, types: [:ack_response])

    assert {:done, :ok} == IntervalSet.handle_response(command, packet)
  end

  test "handles nack response" do
    {:ok, command} = IntervalSet.init(seq_number: 0x01, seconds: 0x01, node_id: 0x01, retries: 0)
    packet = Packet.new(seq_number: 0x01, types: [:nack_response])

    assert {:done, {:error, :nack_response}} == IntervalSet.handle_response(command, packet)
  end

  test "handles retries" do
    {:ok, command} = IntervalSet.init(seq_number: 0x01, seconds: 0x01, node_id: 0x01)
    packet = Packet.new(seq_number: 0x01, types: [:nack_response])

    assert {:retry, %{command | retries: command.retries - 1}} ==
             IntervalSet.handle_response(command, packet)
  end

  test "handles queued for wake up nodes" do
    {:ok, command} = IntervalSet.init(seq_number: 0x01, seconds: 0x01, node_id: 0x01)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(5000)

    assert {:queued, ^command} = IntervalSet.handle_response(command, packet)
  end

  test "handles nack waiting when delay is 1 or less" do
    {:ok, command} = IntervalSet.init(seq_number: 0x01, seconds: 0x01, node_id: 0x01)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(1)

    assert {:continue, ^command} = IntervalSet.handle_response(command, packet)
  end

  test "handles respones" do
    {:ok, command} = IntervalSet.init(seconds: 12, node_id: 1)
    assert {:continue, ^command} = IntervalSet.handle_response(command, Packet.new())
  end
end
