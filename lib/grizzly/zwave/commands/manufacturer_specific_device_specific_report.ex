defmodule Grizzly.ZWave.Commands.ManufacturerSpecificDeviceSpecificReport do
  @moduledoc """
   Module for the DEVICE_SPECIFIC_REPORT command of command class COMMAND_CLASS_MANUFACTURER_SPECIFIC
   Report the manufacturer specific device specific information

  Params:

    * `:device_id_type` - the type of device id reported (required)
    * `:device_id` - unique ID for the device id type (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ManufacturerSpecific
  alias Grizzly.ZWave.DecodeError

  @type device_id_type :: :oem_factory_default_device_id_type | :serial_number | :pseudo_random
  @type device_id :: String.t()
  @type param :: {:device_id_type, device_id_type} | {:device_id, device_id}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :manufacturer_specific_device_specific_report,
      command_byte: 0x08,
      command_class: ManufacturerSpecific,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        <<0x00::5, device_id_type_byte::3, device_id_data_format::3, device_id_data_length::5,
          device_id_integer::size(device_id_data_length)-unit(8)>>
      ) do
    with {:ok, device_id_type} <- device_id_type_from_byte(device_id_type_byte),
         {:ok, device_id} <- device_id_from(device_id_data_format, device_id_integer) do
      {:ok, [device_id_type: device_id_type, device_id: device_id]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    device_id_type = Command.param!(command, :device_id_type)
    device_id = Command.param!(command, :device_id)
    {device_id_data_format, device_id_data_length, device_id_bytes} = encode_device_id(device_id)
    device_id_type_byte = encode_device_id_type(device_id_type)

    <<0x00::5, device_id_type_byte::3, device_id_data_format::3, device_id_data_length::5,
      device_id_bytes::binary>>
  end

  defp device_id_type_from_byte(0x00), do: {:ok, :oem_factory_default_device_id_type}
  defp device_id_type_from_byte(0x01), do: {:ok, :serial_number}
  defp device_id_type_from_byte(0x02), do: {:ok, :pseudo_random}

  defp device_id_type_from_byte(byte),
    do:
      {:error,
       %DecodeError{
         value: byte,
         param: :device_id_type,
         command: :manufacturer_specific_device_specific_report
       }}

  # Binary format
  defp device_id_from(0x01, device_id_integer) do
    device_id = "h'" <> Integer.to_string(device_id_integer, 16)
    {:ok, device_id}
  end

  # UTF-8 format
  defp device_id_from(0x00, device_id_integer) do
    device_id = <<device_id_integer::32>>
    {:ok, device_id}
  end

  defp encode_device_id("h'" <> id) do
    {int_value, ""} = Integer.parse(id, 16)
    bytes = <<int_value::32>>
    {0x01, byte_size(bytes), bytes}
  end

  defp encode_device_id(id) do
    {0x00, byte_size(id), id}
  end

  defp encode_device_id_type(:oem_factory_default_device_id_type), do: 0x00
  defp encode_device_id_type(:serial_number), do: 0x01
  defp encode_device_id_type(:pseudo_random), do: 0x02
end
