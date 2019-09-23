defmodule Grizzly.CommandClass.Powerlevel.TestNodeSet.TestNodeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Powerlevel.TestNodeSet
  alias Grizzly.CommandClass.Powerlevel
  alias Grizzly.Command.EncodeError

  describe "implements the Grizzly command behaviour" do
    test "initializes the command state" do
      {:ok, command} =
        TestNodeSet.init(test_node_id: 5, power_level: :normal_power, test_frame_count: 10)

      assert %TestNodeSet{test_node_id: 5, power_level: :normal_power, test_frame_count: 10} ==
               command
    end

    test "encodes correctly" do
      {:ok, command} =
        TestNodeSet.init(
          test_node_id: 5,
          power_level: :normal_power,
          test_frame_count: 10,
          seq_number: 0x06
        )

      {:ok, level} = Powerlevel.encode_power_level(:normal_power)
      binary = <<35, 2, 128, 208, 6, 0, 0, 3, 2, 0, 0x73, 0x04, 5, level, 0x00, 0x0A>>

      assert {:ok, binary} == TestNodeSet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} =
        TestNodeSet.init(
          test_node_id: 5,
          power_level: :blue,
          test_frame_count: 10,
          seq_number: 0x06
        )

      error = EncodeError.new({:invalid_argument_value, :power_level, :blue, TestNodeSet})

      assert {:error, error} == TestNodeSet.encode(command)
    end

    test "handles an ack response" do
      {:ok, command} =
        TestNodeSet.init(
          test_node_id: 5,
          power_level: :normal_power,
          test_frame_count: 10,
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:done, :ok} == TestNodeSet.handle_response(command, packet)
    end

    test "handles a nack response" do
      {:ok, command} =
        TestNodeSet.init(
          test_node_id: 5,
          power_level: :normal_power,
          test_frame_count: 10,
          seq_number: 0x01,
          retries: 0
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == TestNodeSet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} =
        TestNodeSet.init(
          test_node_id: 5,
          power_level: :normal_power,
          test_frame_count: 10,
          seq_number: 0x01
        )

      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = TestNodeSet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} =
        TestNodeSet.init(
          test_node_id: 5,
          power_level: :normal_power,
          test_frame_count: 10,
          seq_number: 0x01
        )

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = TestNodeSet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} =
        TestNodeSet.init(
          test_node_id: 5,
          power_level: :normal_power,
          test_frame_count: 10,
          seq_number: 0x01
        )

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = TestNodeSet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} =
        TestNodeSet.init(test_node_id: 5, power_level: :normal_power, test_frame_count: 10)

      assert {:continue, _} = TestNodeSet.handle_response(command, %{})
    end
  end
end
