defmodule Grizzly.ZWave.Commands.ManufacturerSpecificDeviceSpecificGet do
  @moduledoc """
  Module for the DEVICE_SPECIFIC_GET command of command class COMMAND_CLASS_MANUFACTURER_SPECIFIC

  Params:
   * `device_id_type` - :oem_factory_default_device_id_type or :serial_number or :pseudo_random (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ManufacturerSpecific
  alias Grizzly.ZWave.DecodeError

  @type device_id_type :: :oem_factory_default_device_id_type | :serial_number | :pseudo_random
  @type param :: {:device_id_type, device_id_type}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :manufacturer_specific_device_specific_get,
      command_byte: 0x06,
      command_class: ManufacturerSpecific,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    device_id_type_byte = encode_device_id_type(Command.param!(command, :device_id_type))
    <<0x00::5, device_id_type_byte::3>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<0x00::5, device_id_type_byte::3>>) do
    case device_id_type_from_byte(device_id_type_byte) do
      {:ok, device_id_type} ->
        {:ok, [device_id_type: device_id_type]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_device_id_type(:oem_factory_default_device_id_type), do: 0x00
  defp encode_device_id_type(:serial_number), do: 0x01
  defp encode_device_id_type(:pseudo_random), do: 0x02

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
end
