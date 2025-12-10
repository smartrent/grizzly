defmodule Grizzly.ZWave.DeviceClasses do
  @moduledoc """
  Z-Wave device classes
  """

  import Grizzly.ZWave.GeneratedMappings,
    only: [
      basic_device_class_mappings: 0,
      generic_device_class_mappings: 0,
      specific_device_class_mappings: 0
    ]

  @type basic_device_class :: atom()
  @type generic_device_class :: atom()
  @type specific_device_class :: atom()

  @doc """
  Try to make a basic device class from a byte
  """
  @spec decode_basic(byte()) :: basic_device_class() | :unknown
  def decode_basic(byte) do
    Enum.find_value(basic_device_class_mappings(), :unknown, fn {dc, b} ->
      if b == byte, do: dc
    end)
  end

  @doc """
  Make a byte from a device class
  """
  @spec encode_basic(basic_device_class()) :: byte()
  def encode_basic(device_class) do
    Map.fetch!(basic_device_class_mappings(), device_class)
  end

  @doc """
  Try to get the generic device class for the byte
  """
  @spec decode_generic(byte()) :: generic_device_class() | :unknown
  def decode_generic(byte) do
    Enum.find_value(generic_device_class_mappings(), :unknown, fn {dc, b} ->
      if b == byte, do: dc
    end)
  end

  @doc """
  Turn the generic device class into a byte
  """
  @spec encode_generic(generic_device_class()) :: byte()
  def encode_generic(device_class) do
    Map.fetch!(generic_device_class_mappings(), device_class)
  end

  @doc """
  Try to get the specific device class from the byte given the generic device class
  """
  @spec decode_specific(generic_device_class(), byte()) ::
          specific_device_class() | :unknown
  def decode_specific(gen_class, byte) do
    Map.get(specific_device_class_mappings(), {gen_class, byte}, :unknown)
  end

  @doc """
  Make the specific device class into a byte
  """
  @spec encode_specific(generic_device_class(), specific_device_class()) :: byte()
  def encode_specific(gen_class, spec_class) do
    Enum.find_value(specific_device_class_mappings(), fn {{g, b}, s} ->
      if g == gen_class and s == spec_class, do: b
    end)
  end
end
