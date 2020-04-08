defmodule Grizzly.CommandClass.Version.GetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Version
  alias Grizzly.CommandClass.Version.Get

  describe "implements Grizzly.Command behaviour" do
    test "initializes command state" do
      assert {:ok, %Get{}} = Get.init([])
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(seq_number: 0x05, command_class: :switch_binary)

      binary = <<35, 2, 128, 208, 5, 0, 0, 3, 2, 0, 0x86, 0x11>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Get.init(seq_number: 0x05)
      packet = Packet.new(seq_number: 0x05, types: [:ack_response])

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Get.init(seq_number: 0x05, retries: 0)

      packet = Packet.new(seq_number: 0x05, types: [:nack_response])
      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Get.init(seq_number: 0x05)
      packet = Packet.new(seq_number: 0x05, types: [:nack_response])

      assert {:retry, %Get{retries: 1}} = Get.handle_response(command, packet)
    end

    test "handles command class version report response" do
      report = %{
        command_class: Version,
        command: :version_report,
        protocol_library: :controller,
        protocol_version: "1.1",
        firmware_version: "1.1"
      }

      packet = Packet.new(body: report)
      {:ok, command} = Get.init(seq_number: 0x05)

      assert {:done, {:ok, Map.drop(report, [:command_class, :command])}} ==
               Get.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = Get.init(seq_number: 0x01, command_class: :switch_binary)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = Get.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles other response" do
      {:ok, command} = Get.init(seq_number: 0x05)

      assert {:continue, ^command} = Get.handle_response(command, %{command: :ice_cream})
    end
  end
end
