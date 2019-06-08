defmodule Grizzly.CommandClass.WakeUp.IntervalGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.WakeUp.IntervalGet

  test "encodes correctly" do
    {:ok, command} = IntervalGet.init(seq_number: 0x01)
    binary = <<35, 2, 128, 208, 1, 0, 0, 3, 2, 0, 0x84, 0x05>>

    assert {:ok, binary} == IntervalGet.encode(command)
  end

  test "handles ack response" do
    {:ok, command} = IntervalGet.init(seq_number: 0x01)
    packet = Packet.new(seq_number: 0x01, types: [:ack_response])

    assert {:continue, ^command} = IntervalGet.handle_response(command, packet)
  end

  test "handle nack response" do
    {:ok, command} = IntervalGet.init(seq_number: 0x01, retries: 0)
    packet = Packet.new(seq_number: 0x01, types: [:nack_response])

    assert {:done, {:error, :nack_response}} == IntervalGet.handle_response(command, packet)
  end

  test "handle retries" do
    {:ok, command} = IntervalGet.init(seq_number: 0x01)
    packet = Packet.new(seq_number: 0x01, types: [:nack_response])

    new_command = %{command | retries: command.retries - 1}

    assert {:retry, new_command} == IntervalGet.handle_response(command, packet)
  end

  test "handles interval report" do
    report = %{
      command_class: :wake_up,
      command: :wake_up_interval_report,
      value: %{seconds: 1, node_id: 10}
    }

    {:ok, command} = IntervalGet.init([])
    packet = Packet.new(body: report)

    assert {:done, %{seconds: 1, node_id: 10}} ==
             IntervalGet.handle_response(command, packet)
  end

  test "handles queued for wake up nodes" do
    {:ok, command} = IntervalGet.init(seq_number: 0x01)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(5000)

    assert {:queued, ^command} = IntervalGet.handle_response(command, packet)
  end

  test "handles nack waiting when delay is 1 or less" do
    {:ok, command} = IntervalGet.init(seq_number: 0x01)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(1)

    assert {:continue, ^command} = IntervalGet.handle_response(command, packet)
  end

  test "handles any response" do
    {:ok, command} = IntervalGet.init([])

    assert {:continue, ^command} = IntervalGet.handle_response(command, %{blah: 1})
  end
end
