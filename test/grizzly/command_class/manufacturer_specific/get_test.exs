defmodule Grizzly.CommandClass.ManufacturerSpecific.GetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ManufacturerSpecific.Get

  describe "implements Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %Get{}} = Get.init(seq_number: 12)
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(seq_number: 0xA0)
      binary = <<35, 2, 128, 208, 160, 0, 0, 3, 2, 0, 0x72, 0x04>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "handle ack response" do
      {:ok, command} = Get.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handle nack response" do
      {:ok, command} = Get.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handle retries" do
      {:ok, command} = Get.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, %Get{retries: 1}} = Get.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = Get.init(seq_number: 0x01)

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

    test "handle manufacturer specific report response" do
      report = %{
        command_class: :manufacturer_specific,
        command: :manufacturer_specific_report,
        value: %{manufacturer_id: 0x1234, product_type_id: 0x5678, product_id: 0x01}
      }

      packet = Packet.new(body: report)

      {:ok, command} = Get.init([])

      assert {:done, {:ok, %{manufacturer_id: 0x1234, product_type_id: 0x5678, product_id: 0x01}}} ==
               Get.handle_response(command, packet)
    end

    test "handle response" do
      {:ok, command} = Get.init([])

      assert {:continue, ^command} = Get.handle_response(command, %{command: :report})
    end
  end
end
