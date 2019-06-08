defmodule Grizzly.CommandClass.ThermostatSetback.Get.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ThermostatSetback.Get

  describe "implements the Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %Get{}} = Get.init(seq_number: 0x09)
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x47, 0x02>>

      assert {:ok, binary} == Get.encode(command)
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

    test "handles thermostat setback report" do
      report = %{
        command_class: :thermostat_setback,
        command: :report,
        report: %{
          type: :temporary_override,
          state: :energy_saving_mode
        }
      }

      {:ok, command} = Get.init(seq_number: 0x01)
      packet = Packet.new(body: report)

      assert {:done,
              {:ok,
               %{
                 type: :temporary_override,
                 state: :energy_saving_mode
               }}} == Get.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = Get.init([])

      assert {:continue, ^command} = Get.handle_response(command, %{value: 100})
    end
  end
end
