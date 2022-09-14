defmodule Grizzly.ZWave.QRCode do
  @moduledoc """
  Z-Wave QR code
  This module handles Z-Wave QR codes that follow Silicon Labs
  Software Design Specification SDS13937 and SDS13944.
  """

  alias Grizzly.ZWave
  alias Grizzly.ZWave.SmartStart.MetaExtension.UUID16

  @typedoc "QR Code version (S2-only or Smart Start-enabled)"
  @type version() :: :s2 | :smart_start

  @typedoc """
  Device information
  * `:zwave_device_type` - either {generic_device_type, specific_device_type} or a number
  """
  @type t() :: %__MODULE__{
          version: version(),
          requested_keys: [ZWave.Security.key()],
          dsk: ZWave.DSK.t(),
          zwave_device_type: {atom(), atom()} | 0..65535,
          zwave_installer_icon: ZWave.IconType.name() | ZWave.IconType.value(),
          manufacturer_id: 0..65535,
          product_type: 0..65535,
          product_id: 0..65535,
          application_version: 0..65535,
          uuid16: nil | UUID16.t()
        }

  defstruct version: :smart_start,
            requested_keys: [],
            dsk: ZWave.DSK.zeros(),
            zwave_device_type: 0,
            zwave_installer_icon: 0,
            manufacturer_id: 0,
            product_type: 0,
            product_id: 0,
            application_version: 0,
            uuid16: nil

  @lead_in "90"

  @doc """
  Encode device information into Z-Wave QR Code format
  The output of this is either a 90 byte or 136 byte string that should be put
  into a QR Code. Z-Wave specifies that the 90-byte code (no UUID16) is made
  into a 29x29 pixel QR Code. The 136-byte* code (w/ UUID16) should be put into
  a 33x33 pixel QR Code.
  QR Codes should be encoded as type "text" with error correction "L".
  NOTE: SDS13937 has a mistake with the code length. It says 134 bytes, but the
  UUID16 encode has 2 extra bytes for presentation, so it should be 136.
  """
  @spec encode!(t()) :: iolist()
  def encode!(info) do
    payload = [
      encode_requested_keys(info.requested_keys),
      encode_dsk(info),
      encode_qr_product_type(info),
      encode_qr_product_id(info),
      encode_uuid16(info.uuid16)
    ]

    [@lead_in, encode_version(info.version), checksum(payload), payload]
  end

  defp checksum(payload) do
    <<two_bytes::16, _rest::144>> = :crypto.hash(:sha, payload)
    int_to_string(two_bytes, 5)
  end

  defp encode_version(:s2), do: "00"
  defp encode_version(:smart_start), do: "01"

  defp encode_requested_keys(requested_keys) do
    ZWave.Security.keys_to_byte(requested_keys)
    |> int_to_string(3)
  end

  defp encode_dsk(info), do: ZWave.DSK.to_string(info.dsk, delimiter: "")

  defp encode_qr_product_type(info) do
    # QR Product type = TLV type 00, length 10
    [
      "0010",
      encode_device_type(info.zwave_device_type),
      encode_icon_type(info.zwave_installer_icon)
    ]
  end

  defp encode_device_type({generic, specific}) do
    device_type =
      ZWave.DeviceClasses.generic_device_class_to_byte(generic) * 256 +
        ZWave.DeviceClasses.specific_device_class_to_byte(generic, specific)

    encode_device_type(device_type)
  end

  defp encode_device_type(device_type) when is_integer(device_type) do
    int_to_string(device_type, 5)
  end

  defp encode_icon_type(type) when is_atom(type) do
    {:ok, value} = ZWave.IconType.to_value(type)
    encode_icon_type(value)
  end

  defp encode_icon_type(type), do: int_to_string(type, 5)

  defp encode_qr_product_id(info) do
    # QR Product ID = TLV type 02, length 20
    [
      "0220",
      int_to_string(info.manufacturer_id, 5),
      int_to_string(info.product_type, 5),
      int_to_string(info.product_id, 5),
      int_to_string(info.application_version, 5)
    ]
  end

  defp encode_uuid16(nil), do: []

  defp encode_uuid16(uuid16) do
    value = UUID16.encode(uuid16)
    <<0x06, 0x11, presentation, uuid::binary>> = value

    decimalized_uuid =
      uuid
      |> ZWave.DSK.new()
      |> ZWave.DSK.to_string(delimiter: "")

    # UUID16 = TLV type 06, length 42
    ["0642", int_to_string(presentation, 2), decimalized_uuid]
  end

  defp int_to_string(value, num_digits) when value >= 0 do
    value
    |> Integer.to_string(10)
    |> String.pad_leading(num_digits, "0")
  end
end
