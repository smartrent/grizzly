defmodule Grizzly.CommandClass.Association.GetTest do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.Association.Get
  alias Grizzly.Packet

  test "encodes correctly" do
    command = make_command(1)
    expected_binary = Packet.header(1) <> <<0x85, 0x02, 0x01>>

    assert {:ok, expected_binary} == Get.encode(command)
  end

  test "handles ack_response" do
    command = make_command(1)
    packet = Packet.new(seq_number: 1, types: [:ack_response])

    assert {:continue, command} == Get.handle_response(command, packet)
  end

  test "handles nack_reponse with retries" do
    command = make_command(1)
    packet = Packet.new(seq_number: 1, types: [:nack_response])

    assert {:retry, %{command | retries: command.retries - 1}} ==
             Get.handle_response(command, packet)
  end

  test "handles nack_response no retires" do
    {:ok, command} = Get.init(seq_number: 1, group: 1, retries: 0)
    packet = Packet.new(seq_number: 1, types: [:nack_response])

    assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
  end

  test "handles queued for wake up nodes" do
    command = make_command(1)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(5000)

    assert {:queued, command} == Get.handle_response(command, packet)
  end

  test "handles nack waiting when delay is 1 second or less" do
    command = make_command(1)

    packet =
      Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
      |> Packet.put_expected_delay(1)

    assert {:continue, command} == Get.handle_response(command, packet)
  end

  test "handles association report" do
    command = make_command(1)

    body = %{
      command_class: :association,
      command: :report,
      nodes: [1]
    }

    packet = Packet.new(body: body)

    assert {:done, {:ok, [1]}} == Get.handle_response(command, packet)
  end

  test "handles other types of packets" do
    command = make_command(1)
    packet = Packet.new(body: %{command_class: :battery})

    assert {:continue, command} == Get.handle_response(command, packet)
  end

  defp make_command(group) do
    {:ok, command} = Get.init(seq_number: 1, group: group)
    command
  end
end
