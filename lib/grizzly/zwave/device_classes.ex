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

  basic_mappings = basic_device_class_mappings()
  generic_mappings = generic_device_class_mappings()
  specific_mappings = specific_device_class_mappings()

  basic_classes_union =
    basic_mappings
    |> Enum.map(&elem(&1, 1))
    |> Enum.reverse()
    |> Enum.reduce(&{:|, [], [&1, &2]})

  generic_classes_union =
    generic_mappings
    |> Enum.map(&elem(&1, 1))
    |> Enum.reverse()
    |> Enum.reduce(&{:|, [], [&1, &2]})

  specific_classes_union =
    specific_mappings
    |> Enum.map(&elem(&1, 2))
    |> Enum.reverse()
    |> Enum.uniq()
    |> Enum.reduce(&{:|, [], [&1, &2]})

  @type basic_device_class :: unquote(basic_classes_union)
  @type generic_device_class :: unquote(generic_classes_union)
  @type specific_device_class :: unquote(specific_classes_union)

  @doc """
  Try to make a basic device class from a byte
  """
  @spec decode_basic(byte()) :: basic_device_class() | :unknown
  for {byte, device_class} <- basic_mappings do
    def decode_basic(unquote(byte)), do: unquote(device_class)
  end

  def decode_basic(_byte), do: :unknown

  @doc """
  Make a byte from a device class
  """
  @spec encode_basic(basic_device_class()) :: byte()
  for {byte, device_class} <- basic_mappings do
    def encode_basic(unquote(device_class)), do: unquote(byte)
  end

  @doc """
  Try to get the generic device class for the byte
  """
  @spec decode_generic(byte()) :: generic_device_class() | :unknown
  for {byte, device_class} <- generic_mappings do
    def decode_generic(unquote(byte)), do: unquote(device_class)
  end

  def decode_generic(_byte), do: :unknown

  @doc """
  Turn the generic device class into a byte
  """
  @spec encode_generic(generic_device_class()) :: byte()
  for {byte, device_class} <- generic_mappings do
    def encode_generic(unquote(device_class)), do: unquote(byte)
  end

  @doc """
  Try to get the specific device class from the byte given the generic device class
  """
  @spec decode_specific(generic_device_class(), byte()) ::
          specific_device_class() | :unknown
  for {gen_class, byte, spec_class} <- specific_mappings do
    def decode_specific(unquote(gen_class), unquote(byte)),
      do: unquote(spec_class)
  end

  def decode_specific(_, _byte), do: :unknown

  @doc """
  Make the specific device class into a byte
  """
  @spec encode_specific(generic_device_class(), specific_device_class()) :: byte()
  for {gen_class, byte, spec_class} <- specific_mappings do
    def encode_specific(unquote(gen_class), unquote(spec_class)),
      do: unquote(byte)
  end
end
