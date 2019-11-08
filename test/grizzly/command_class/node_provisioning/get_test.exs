defmodule Grizzly.CommandClass.NodeProvisioning.GetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NodeProvisioning.Get

  describe "implements the Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %Get{}} = Get.init(seq_number: 0x09)
    end

    test "encodes correctly" do
      binary_dsk = <<196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

      {:ok, command} =
        Get.init(seq_number: 0x08, dsk: "50285-18819-09924-30691-15973-33711-04005-03623")

      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x78, 0x05, 0x08, 0x10>> <> binary_dsk

      assert {:ok, binary} == Get.encode(command)
    end

    test "does not encode too long dsk" do
      {:ok, command} =
        Get.init(seq_number: 0x08, dsk: "50285-18819-09924-30691-15973-33711-04005-03623-12345")

      assert {:error, %Grizzly.Command.EncodeError{}} = Get.encode(command)
    end

    test "does not encode too short dsk" do
      {:ok, command} =
        Get.init(seq_number: 0x08, dsk: "09924-30691-15973-33711-04005-03623-12345")

      assert {:error, %Grizzly.Command.EncodeError{}} = Get.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Get.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Get.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handles retires" do
      {:ok, command} = Get.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, %Get{}} = Get.handle_response(command, packet)
    end

    test "handles node provisioning report" do
      expected_dsk = "50285-18819-09924-30691-15973-33711-04005-03623"

      report = %{
        command_class: :node_provisioning,
        command: :report,
        dsk: expected_dsk
      }

      {:ok, command} = Get.init(seq_number: 0x01)
      packet = Packet.new(body: report)

      assert {:done, {:ok, expected_dsk}} == Get.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = Get.init([])

      assert {:continue, ^command} = Get.handle_response(command, %{value: 100})
    end
  end
end
