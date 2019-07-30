defmodule Grizzly.CommandClass.SensorMultilevel.SupportedGetSensor.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.SensorMultilevel.SupportedGetSensor

  describe "implements the Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %SupportedGetSensor{}} = SupportedGetSensor.init(seq_number: 0x09)
    end

    test "encodes correctly" do
      {:ok, command} = SupportedGetSensor.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x31, 0x01>>

      assert {:ok, binary} == SupportedGetSensor.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = SupportedGetSensor.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, ^command} = SupportedGetSensor.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = SupportedGetSensor.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               SupportedGetSensor.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = SupportedGetSensor.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, %SupportedGetSensor{retries: 1}} =
               SupportedGetSensor.handle_response(command, packet)
    end

    test "handles sensor multilevel report" do
      report = %{
        command_class: :sensor_multilevel,
        command: :supported_sensor_report,
        value: [:illuminance, :power]
      }

      {:ok, command} = SupportedGetSensor.init([])
      packet = Packet.new(body: report)

      assert {:done, {:ok, [:illuminance, :power]}} ==
               SupportedGetSensor.handle_response(command, packet)
    end

    test "handles other responses" do
      {:ok, command} = SupportedGetSensor.init([])

      assert {:continue, ^command} = SupportedGetSensor.handle_response(command, %{value: 100})
    end
  end
end
