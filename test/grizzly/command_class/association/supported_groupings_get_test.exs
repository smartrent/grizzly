defmodule Grizzly.CommandClass.Association.SupportedGroupingsGet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Association.SupportedGroupingsGet

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %SupportedGroupingsGet{}} = SupportedGroupingsGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = SupportedGroupingsGet.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x85, 0x05>>

      assert {:ok, binary} == SupportedGroupingsGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = SupportedGroupingsGet.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %SupportedGroupingsGet{}} =
               SupportedGroupingsGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = SupportedGroupingsGet.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               SupportedGroupingsGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = SupportedGroupingsGet.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = SupportedGroupingsGet.handle_response(command, packet)
    end

    test "handles basic report responses" do
      report = %{
        command_class: :association,
        command: :association_groupings_report,
        value: 5
      }

      {:ok, command} = SupportedGroupingsGet.init([])
      packet = Packet.new(body: report)

      assert {:done, {:ok, 5}} ==
               SupportedGroupingsGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = SupportedGroupingsGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = SupportedGroupingsGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = SupportedGroupingsGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = SupportedGroupingsGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = SupportedGroupingsGet.init([])

      assert {:continue, %SupportedGroupingsGet{}} ==
               SupportedGroupingsGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
