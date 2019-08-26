defmodule Grizzly.CommandClass.Powerlevel.GetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Powerlevel.Get

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %Get{}} = Get.init([])
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x73, 0x02>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = Get.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %Get{}} = Get.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = Get.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Get.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = Get.handle_response(command, packet)
    end

    test "handles basic report responses" do
      report = %{
        command_class: :powerlevel,
        command: :power_level_report,
        value: %{power_level: :normal_power, timeout: 1}
      }

      {:ok, command} = Get.init([])
      packet = Packet.new(body: report)

      assert {:done, {:ok, %{power_level: :normal_power, timeout: 1}}} ==
               Get.handle_response(command, packet)
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

    test "handles response" do
      {:ok, command} = Get.init([])

      assert {:continue, %Get{}} ==
               Get.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
