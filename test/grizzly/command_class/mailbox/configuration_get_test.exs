defmodule Grizzly.CommandClass.Mailbox.ConfigurationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.Mailbox.ConfigurationGet
  alias Grizzly.Packet

  test "encodes correctly" do
    {:ok, command} = ConfigurationGet.init(seq_number: 0x01)
    assert {:ok, Packet.header(0x01) <> <<0x69, 0x01>>} == ConfigurationGet.encode(command)
  end

  test "handles ack response" do
    {:ok, command} = ConfigurationGet.init(seq_number: 0x01)
    packet = Packet.new(seq_number: 0x01, types: [:ack_response])

    assert {:continue, ^command} = ConfigurationGet.handle_response(command, packet)
  end

  test "handles nack reponse with retries" do
    {:ok, command} = ConfigurationGet.init(seq_number: 0x01)
    packet = Packet.new(seq_number: 0x01, types: [:nack_response])

    retried_command = %{command | retries: 1}

    assert {:retry, ^retried_command} = ConfigurationGet.handle_response(command, packet)
  end

  test "handle nack response with no more retires" do
    {:ok, command} = ConfigurationGet.init(seq_number: 0x01, retries: 0)
    packet = Packet.new(seq_number: 0x01, types: [:nack_response])

    assert {:done, {:error, :nack_response}} = ConfigurationGet.handle_response(command, packet)
  end

  test "handles when we get a report" do
    report = %{command_class: :mailbox, command: :configuration_report}
    packet = Packet.new(body: report)
    {:ok, command} = ConfigurationGet.init()

    assert {:done, {:ok, ^report}} = ConfigurationGet.handle_response(command, packet)
  end

  test "handles queued for wake up nodes" do
    {:ok, command} = ConfigurationGet.init(seq_number: 0x01)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(5000)

    assert {:queued, ^command} = ConfigurationGet.handle_response(command, packet)
  end

  test "handles nack waiting when delay is 1 or less" do
    {:ok, command} = ConfigurationGet.init(seq_number: 0x01)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(1)

    assert {:continue, ^command} = ConfigurationGet.handle_response(command, packet)
  end

  test "passes through other messages" do
    {:ok, command} = ConfigurationGet.init(seq_number: 0x01)

    assert {:continue, ^command} =
             ConfigurationGet.handle_response(command, %{command_class: :foo})
  end
end
