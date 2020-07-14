defmodule Grizzly.ZWave.CommandClasses.MultiChannel do
  @moduledoc """
  "MultiChannel" Command Class

  The Multi Channel command class is used to address one or more End Points in a Multi Channel device.
  """

  alias Grizzly.ZWave.{DecodeError, DeviceClasses}
  @behaviour Grizzly.ZWave.CommandClass

  @type end_point :: 1..127

  @impl true
  def byte(), do: 0x60

  @impl true
  def name(), do: :multi_channel

  @spec decode_generic_device_class(byte) ::
          {:ok, DeviceClasses.generic_device_class()} | {:error, DecodeError.t()}
  def decode_generic_device_class(generic_device_class_byte) do
    case DeviceClasses.generic_device_class_from_byte(generic_device_class_byte) do
      {:ok, generic_device_class} ->
        {:ok, generic_device_class}

      {:error, :unsupported_device_class} ->
        {:error,
         %DecodeError{
           value: generic_device_class_byte,
           param: :generic_device_class,
           command: :multi_channel_capability_report
         }}
    end
  end

  @spec decode_specific_device_class(DeviceClasses.generic_device_class(), byte) ::
          {:ok, DeviceClasses.specific_device_class()} | {:error, DecodeError.t()}
  def decode_specific_device_class(
        generic_device_class,
        specific_device_class_byte
      ) do
    case DeviceClasses.specific_device_class_from_byte(
           generic_device_class,
           specific_device_class_byte
         ) do
      {:ok, specific_device_class} ->
        {:ok, specific_device_class}

      {:error, :unsupported_device_class} ->
        {:error,
         %DecodeError{
           value: specific_device_class_byte,
           param: :specific_device_class,
           command: :multi_channel_capability_report
         }}
    end
  end
end
