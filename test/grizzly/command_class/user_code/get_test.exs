defmodule Grizzly.CommandClass.UserCode.Get.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.UserCode.Get
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %Get{}} == Get.init([])
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(seq_number: 10, slot_id: 0x01)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x63, 0x02, 0x01>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = Get.init(seq_number: 10, slot_id: :blue)

      error = EncodeError.new({:invalid_argument_value, :slot_id, :blue, Get})

      assert {:error, error} == Get.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = Get.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:ack_response])

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack respones" do
      {:ok, command} = Get.init(seq_number: 0x01, retries: 0)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Get.init(seq_number: 0x01)
      packet = Packet.new(seq_number: 0x01, types: [:nack_response])

      assert {:retry, _command} = Get.handle_response(command, packet)
    end

    test "handles user code report response" do
      report = %{command_class: :user_code, command: :report, value: [1, 2, 3, 4]}
      {:ok, command} = Get.init(seq_number: 0x04)
      packet = Packet.new(body: report)

      assert {:done, {:ok, [1, 2, 3, 4]}} == Get.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Get.init([])
      assert {:continue, %Get{}} = Get.handle_response(command, %{command_class: :foo})
    end
  end
end
