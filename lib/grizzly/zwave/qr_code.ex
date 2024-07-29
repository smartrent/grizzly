defmodule Grizzly.ZWave.QRCode do
  @moduledoc """
  Z-Wave QR code
  This module handles Z-Wave QR codes that follow Silicon Labs
  Software Design Specification SDS13937 and SDS13944.
  """

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{DSK, Security}
  alias Grizzly.ZWave.SmartStart.MetaExtension.UUID16

  require Logger

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
          application_version: {byte(), byte()} | nil,
          uuid16: nil | UUID16.t(),
          supported_protocols: any()
        }

  defstruct version: :smart_start,
            requested_keys: [],
            dsk: ZWave.DSK.zeros(),
            zwave_device_type: 0,
            zwave_installer_icon: 0,
            manufacturer_id: 0,
            product_type: 0,
            product_id: 0,
            application_version: nil,
            uuid16: nil,
            supported_protocols: []

  @lead_in "90"

  @spec decode(<<_::16, _::_*8>>) :: {:ok, t()} | {:error, :invalid_dsk}
  def decode(@lead_in <> binary) do
    {version, binary} = String.split_at(binary, 2)
    {_checksum, binary} = String.split_at(binary, 5)
    {requested_keys, binary} = String.split_at(binary, 3)
    {dsk, binary} = String.split_at(binary, 40)

    requested_keys = requested_keys |> String.to_integer() |> Security.byte_to_keys()

    case DSK.parse(dsk) do
      {:ok, dsk} ->
        tlv = decode_tlv(binary)

        app_version =
          if is_list(tlv[:product_id]) do
            {tlv[:product_id][:app_version], tlv[:product_id][:app_sub_version]}
          else
            nil
          end

        {:ok,
         %__MODULE__{
           version: decode_version(version),
           requested_keys: requested_keys,
           dsk: dsk,
           zwave_device_type:
             {tlv[:product_type][:generic_device_class],
              tlv[:product_type][:specific_device_class]},
           zwave_installer_icon: tlv[:product_type][:installer_icon],
           manufacturer_id: tlv[:product_id][:manufacturer_id],
           product_type: tlv[:product_id][:product_type],
           product_id: tlv[:product_id][:product_id],
           application_version: app_version,
           uuid16: tlv[:uuid_16],
           supported_protocols: tlv[:supported_protocols] || []
         }}

      {:error, _} ->
        {:error, :invalid_dsk}
    end
  end

  defp decode_tlv(binary, acc \\ [])
  defp decode_tlv("", acc), do: acc

  defp decode_tlv(binary, acc) when byte_size(binary) > 2 do
    {tag_critical, binary} = String.split_at(binary, 2)
    <<tag::7, _critical::1>> = <<String.to_integer(tag_critical)::8>>

    # critical = if(critical == 1, do: true, else: false)
    {length, binary} = String.split_at(binary, 2)
    length = String.to_integer(length)
    {value, binary} = String.split_at(binary, length)

    tag = decode_tag(tag)

    decode_tlv(binary, [{tag, decode_value(tag, value)} | acc])
  end

  defp decode_tlv(binary, acc) when byte_size(binary) > 0 do
    Logger.warning("QR Code contains invalid TLV segment (too short): #{binary}")
    acc
  end

  defp decode_tlv(<<>>, acc), do: acc

  defp decode_tag(0x00), do: :product_type
  defp decode_tag(0x01), do: :product_id
  defp decode_tag(0x02), do: :max_inclusion_request_interval
  defp decode_tag(0x03), do: :uuid_16
  defp decode_tag(0x04), do: :supported_protocols
  defp decode_tag(0x32), do: :name
  defp decode_tag(0x33), do: :location
  defp decode_tag(0x34), do: :smartstart_inclusion_setting
  defp decode_tag(0x35), do: :advanced_joinin
  defp decode_tag(0x36), do: :bootstrapping_mode
  defp decode_tag(0x37), do: :network_status

  defp decode_value(:product_type, value) do
    {classes, installer_icon} = String.split_at(value, 5)
    <<generic::8, specific::8>> = <<String.to_integer(classes)::16>>
    installer_icon = String.to_integer(installer_icon)

    {:ok, generic_device_class} = ZWave.DeviceClasses.generic_device_class_from_byte(generic)

    {:ok, specific_device_class} =
      ZWave.DeviceClasses.specific_device_class_from_byte(
        generic_device_class,
        specific
      )

    {:ok, installer_icon} = ZWave.IconType.to_name(installer_icon)

    %{
      generic_device_class: generic_device_class,
      specific_device_class: specific_device_class,
      installer_icon: installer_icon
    }
  end

  defp decode_value(:product_id, value) do
    [manufacturer_id, product_type, product_id, vsn] =
      value
      |> String.to_charlist()
      |> Enum.chunk_every(5)
      |> Enum.map(&String.to_integer(to_string(&1)))

    <<app_version::8, app_sub_version::8>> = <<vsn::16>>

    [
      manufacturer_id: manufacturer_id,
      product_type: product_type,
      product_id: product_id,
      app_version: app_version,
      app_sub_version: app_sub_version
    ]
  end

  defp decode_value(:uuid_16, value) do
    <<_presentation::2-bytes, decimalized_uuid::binary>> = value

    ints =
      decimalized_uuid
      |> String.to_charlist()
      |> Enum.chunk_every(5)
      |> Enum.map(&String.to_integer(to_string(&1)))

    uuid_string =
      for int <- ints, into: <<>> do
        <<int::16>>
      end

    {:ok, uuid} = Base.encode16(uuid_string) |> UUID16.new(:hex)

    uuid
  end

  defp decode_value(:supported_protocols, value) do
    {int_val, ""} = Integer.parse(value)

    <<_reserved::6, zwave_lr::1, zwave::1, _rest::binary>> = <<int_val>>
    protocols = if(zwave_lr == 1, do: [:zwave_lr], else: [])
    if(zwave == 1, do: [:zwave | protocols], else: protocols)
  end

  defp decode_value(_, value), do: value

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

  defp decode_version("00"), do: :s2
  defp decode_version("01"), do: :smart_start

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
    app_version =
      cond do
        is_tuple(info.application_version) && tuple_size(info.application_version) == 2 ->
          {app_version, app_sub_version} = info.application_version
          <<vsn::16>> = <<app_version, app_sub_version>>
          int_to_string(vsn, 5)

        is_integer(info.application_version) ->
          int_to_string(info.application_version, 5)

        true ->
          int_to_string(0, 5)
      end

    # QR Product ID = TLV type 02, length 20
    [
      "0220",
      int_to_string(info.manufacturer_id, 5),
      int_to_string(info.product_type, 5),
      int_to_string(info.product_id, 5),
      app_version
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
