defmodule Grizzly.ZWave.CommandClasses.MultiChannel do
  @moduledoc """
  "MultiChannel" Command Class

  The Multi Channel command class is used to address one or more End Points in a Multi Channel device.
  """

  alias Grizzly.ZWave.DeviceClasses
  @behaviour Grizzly.ZWave.CommandClass

  @type end_point :: 1..127

  @impl true
  def byte(), do: 0x60

  @impl true
  def name(), do: :multi_channel

  @spec decode_generic_device_class(byte) :: {:ok, DeviceClasses.generic_device_class()}
  @deprecated "Use `Grizzly.ZWave.DeviceClasses.generic_device_class_from_byte/1` instead"
  def decode_generic_device_class(generic_device_class_byte) do
    DeviceClasses.generic_device_class_from_byte(generic_device_class_byte)
  end

  @spec decode_specific_device_class(DeviceClasses.generic_device_class(), byte) ::
          {:ok, DeviceClasses.specific_device_class()}
  @deprecated "Use `Grizzly.ZWave.DeviceClasses.specific_device_class_from_byte/2` instead"
  def decode_specific_device_class(
        generic_device_class,
        specific_device_class_byte
      ) do
    DeviceClasses.specific_device_class_from_byte(
      generic_device_class,
      specific_device_class_byte
    )
  end
end
