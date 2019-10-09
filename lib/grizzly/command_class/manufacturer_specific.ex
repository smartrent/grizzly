defmodule Grizzly.CommandClass.ManufacturerSpecific do
  require Logger

  @type device_id_type :: :oem_factory_default_device_id_type | :serial_number | :pseudo_random
  @type device_id_type_byte :: 0 | 1 | 2
  @type device_id_data_format :: :utf8 | :binary
  @type device_id_data_format_byte :: 0 | 1
  @type device_specific_report :: %{device_id_type: device_id_type, device_id: binary}
  @type manufacturer_report :: %{
          manufacturer_id: non_neg_integer,
          product_type_id: non_neg_integer,
          product_id: non_neg_integer
        }

  @spec encode_device_id_type(device_id_type) ::
          {:ok, device_id_type_byte} | {:error, :invalid_arg, any()}
  def encode_device_id_type(device_id_type) do
    case device_id_type do
      :oem_factory_default_device_id_type -> {:ok, 0}
      :serial_number -> {:ok, 1}
      :pseudo_random -> {:ok, 2}
      other -> {:error, :invalid_arg, other}
    end
  end

  @spec decode_device_id_type(device_id_type_byte) :: device_id_type
  def decode_device_id_type(byte) do
    case byte do
      0 -> :oem_factory_default_device_id_type
      1 -> :serial_number
      2 -> :pseudo_random
    end
  end

  @spec decode_device_id_data_format(device_id_data_format_byte) :: device_id_data_format
  def decode_device_id_data_format(enc_format) do
    case enc_format do
      0 -> :utf8
      1 -> :binary
    end
  end
end
