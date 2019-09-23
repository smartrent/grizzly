defmodule Grizzly.CommandClass.SensorMultilevel.Get.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.SensorMultilevel.Get
  alias Grizzly.Command.EncodeError

  describe "implements the Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %Get{}} = Get.init(seq_number: 0x09)
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x31, 0x04>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "encodes correctly version 4+" do
      {:ok, command} = Get.init(seq_number: 0x08, sensor_type: :humidity)

      binary =
        <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x31, 0x04, 0x05, 0x00::size(3), 0x01::size(2),
          0x00::size(3)>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = Get.init(sensor_type: :vibes, seq_number: 0x06)

      error = EncodeError.new({:invalid_argument_value, :sensor_type, :vibes, Get})

      assert {:error, error} == Get.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Get.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Get.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Get.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, %Get{retries: 1}} = Get.handle_response(command, packet)
    end

    test "handles sensor multilevel report" do
      report = %{command_class: :sensor_multilevel, command: :report, value: 90}
      {:ok, command} = Get.init([])
      packet = Packet.new(body: report)

      assert {:done, {:ok, 90}} == Get.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = Get.init([])

      assert {:continue, ^command} = Get.handle_response(command, %{value: 100})
    end
  end
end
