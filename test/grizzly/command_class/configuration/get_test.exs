defmodule Grizzly.CommandClass.Configuration.Get.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Configuration
  alias Grizzly.CommandClass.Configuration.Get
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %Get{}} == Get.init([])
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(seq_number: 10, configuration_param: 0x01)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x70, 0x05, 0x01>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = Get.init(configuration_param: 1000, seq_number: 0x06)

      error =
        EncodeError.new(
          {:invalid_argument_value, :configuration_param, 1000,
           Grizzly.CommandClass.Configuration.Get}
        )

      assert {:error, error} == Get.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = Get.init(seq_number: 0x05)
      packet = Packet.new(seq_number: 0x5, types: [:ack_response])

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack respones" do
      {:ok, command} = Get.init(seq_number: 0x06, retries: 0)
      packet = Packet.new(seq_number: 0x06, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handles retires" do
      {:ok, command} = Get.init(seq_number: 0x06)
      packet = Packet.new(seq_number: 0x06, types: [:nack_response])

      assert {:retry, %Get{retries: 1}} = Get.handle_response(command, packet)
    end

    test "handles configuration report response" do
      report = %{command_class: Configuration, command: :report, value: 10}
      packet = Packet.new(body: report)
      {:ok, command} = Get.init([])

      assert {:done, {:ok, 10}} == Get.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = Get.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, command} == Get.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = Get.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, command} == Get.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Get.init([])
      assert {:continue, %Get{}} = Get.handle_response(command, %{command_class: :foo})
    end
  end
end
