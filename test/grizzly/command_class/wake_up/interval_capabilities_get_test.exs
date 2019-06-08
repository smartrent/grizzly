defmodule Grizzly.CommandClass.WakeUp.IntervalCapabilitiesGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.WakeUp.IntervalCapabilitiesGet
  alias Grizzly.Packet
  alias Grizzly.Packet.BodyParser

  test "encodes correctly" do
    {:ok, command} = IntervalCapabilitiesGet.init(seq_number: 0x1)
    expected_binary = Packet.header(0x01) <> <<0x84, 0x09>>

    {:ok, ^expected_binary} = IntervalCapabilitiesGet.encode(command)
  end

  test "handles ack response" do
    {:ok, command} = IntervalCapabilitiesGet.init(seq_number: 0x01)
    packet = Packet.new(seq_number: 0x01, types: [:ack_response])
    assert {:continue, ^command} = IntervalCapabilitiesGet.handle_response(command, packet)
  end

  test "handles nack_response" do
    {:ok, command} = IntervalCapabilitiesGet.init(seq_number: 0x01, retries: 0)
    packet = Packet.new(seq_number: 0x01, types: [:nack_response])

    assert {:done, {:error, :nack_response}} ==
             IntervalCapabilitiesGet.handle_response(command, packet)
  end

  test "handles nack_response with retries" do
    {:ok, command} = IntervalCapabilitiesGet.init(seq_number: 0x01, retries: 1)
    packet = Packet.new(seq_number: 0x01, types: [:nack_response])

    assert {:retry, %{command | retries: 0}} ==
             IntervalCapabilitiesGet.handle_response(command, packet)
  end

  test "handles queued for wake up nodes" do
    {:ok, command} = IntervalCapabilitiesGet.init(seq_number: 0x01)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(5000)

    assert {:queued, ^command} = IntervalCapabilitiesGet.handle_response(command, packet)
  end

  test "handles nack waiting when delay is 1 or less" do
    {:ok, command} = IntervalCapabilitiesGet.init(seq_number: 0x01)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(1)

    assert {:continue, ^command} = IntervalCapabilitiesGet.handle_response(command, packet)
  end

  test "handles interval capabilites report" do
    {:ok, command} = IntervalCapabilitiesGet.init(seq_number: 0x01)
    report = BodyParser.parse(<<0x84, 0x0A, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1>>)
    packet = Packet.new(body: report)

    expected_report = %{
      default_interval: 1,
      interval_step: 1,
      max_interval: 1,
      min_interval: 1
    }

    assert {:done, {:ok, expected_report}} ==
             IntervalCapabilitiesGet.handle_response(command, packet)
  end
end
