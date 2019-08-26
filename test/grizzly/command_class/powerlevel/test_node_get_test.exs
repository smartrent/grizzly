defmodule Grizzly.CommandClass.Powerlevel.TestNodeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Powerlevel.TestNodeGet

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %TestNodeGet{}} = TestNodeGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = TestNodeGet.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x73, 0x05>>

      assert {:ok, binary} == TestNodeGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = TestNodeGet.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %TestNodeGet{}} = TestNodeGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = TestNodeGet.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == TestNodeGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = TestNodeGet.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = TestNodeGet.handle_response(command, packet)
    end

    test "handles basic report responses" do
      report = %{
        command_class: :powerlevel,
        command: :test_node_report,
        value: %{test_node_id: 5, status_of_operation: :test_success, test_frame_count: 10}
      }

      {:ok, command} = TestNodeGet.init([])
      packet = Packet.new(body: report)

      assert {:done,
              {:ok, %{test_node_id: 5, status_of_operation: :test_success, test_frame_count: 10}}} ==
               TestNodeGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = TestNodeGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = TestNodeGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = TestNodeGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = TestNodeGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = TestNodeGet.init([])

      assert {:continue, %TestNodeGet{}} ==
               TestNodeGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
