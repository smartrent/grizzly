defmodule Grizzly.CommandClass.ManufacturerSpecific.DeviceSpecificGet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ManufacturerSpecific.DeviceSpecificGet
  alias Grizzly.CommandClass.ManufacturerSpecific
  alias Grizzly.Command.EncodeError

  describe "implements Grizzly.Command behaviour" do
    test "initializes command" do
      assert {:ok, %DeviceSpecificGet{}} =
               DeviceSpecificGet.init(seq_number: 12, device_id_type: :serial_number)
    end

    test "encodes correctly" do
      {:ok, command} = DeviceSpecificGet.init(seq_number: 0xA0, device_id_type: :serial_number)

      {:ok, encoded_device_id_type} = ManufacturerSpecific.encode_device_id_type(:serial_number)

      binary =
        <<35, 2, 128, 208, 160, 0, 0, 3, 2, 0, 0x72, 0x06, 0x00::size(5),
          encoded_device_id_type::size(3)>>

      assert {:ok, binary} == DeviceSpecificGet.encode(command)
    end

    test "encodes incorrectly" do
      {:ok, command} = DeviceSpecificGet.init(device_id_type: :blue, seq_number: 0x06)

      error =
        EncodeError.new(
          {:invalid_argument_value, :device_id_type, :blue,
           Grizzly.CommandClass.ManufacturerSpecific.DeviceSpecificGet}
        )

      assert {:error, error} == DeviceSpecificGet.encode(command)
    end

    test "handle ack response" do
      {:ok, command} = DeviceSpecificGet.init(seq_number: 0x10, device_id_type: :serial_number)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, ^command} = DeviceSpecificGet.handle_response(command, packet)
    end

    test "handle nack response" do
      {:ok, command} = DeviceSpecificGet.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               DeviceSpecificGet.handle_response(command, packet)
    end

    test "handle retries" do
      {:ok, command} = DeviceSpecificGet.init(seq_number: 0x10, device_id_type: :serial_number)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, %DeviceSpecificGet{retries: 1}} =
               DeviceSpecificGet.handle_response(command, packet)
    end

    test "handle device specific report response" do
      body = %{
        command_class: :manufacturer_specific,
        command: :device_specific_report,
        value: %{device_id_type: :serial_number, device_id: "PQ"}
      }

      packet = Packet.new(body: body)

      {:ok, command} = DeviceSpecificGet.init(seq_number: 0x10, device_id_type: :serial_number)

      assert {:done, {:ok, %{device_id_type: :serial_number, device_id: "PQ"}}} ==
               DeviceSpecificGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = DeviceSpecificGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = DeviceSpecificGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = DeviceSpecificGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = DeviceSpecificGet.handle_response(command, packet)
    end

    test "handle response" do
      {:ok, command} = DeviceSpecificGet.init([])

      assert {:continue, ^command} =
               DeviceSpecificGet.handle_response(command, %{command: :report})
    end
  end
end
