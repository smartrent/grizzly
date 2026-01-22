defmodule Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions do
  @moduledoc """
  Functions for working with the header extension in a Z/IP Packet.
  """

  alias Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.EncapsulationFormatInfo
  alias Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.InstallationAndMaintenanceReport
  alias Grizzly.ZWave.Encoding

  require Logger

  @type encapsulation_format_info :: :crc16 | EncapsulationFormatInfo.security()

  @type extension ::
          {:expected_delay, non_neg_integer()}
          | {:installation_and_maintenance_report, list()}
          | :installation_and_maintenance_get
          | {:encapsulation_format_info, [encapsulation_format_info()]}
          | :multicast_addressing

  @doc """
  Try to parse a binary string into `HeaderExtensions.t()`
  """
  @spec from_binary(binary()) :: [extension()]
  def from_binary(extensions) do
    extensions
    |> Encoding.reduce_binary(&parse_extension/2)
    |> Enum.reverse()
  end

  @spec to_binary([extension()]) :: binary()
  def to_binary(extensions) do
    Enum.reduce(extensions, <<>>, fn
      {:expected_delay, seconds}, bin ->
        bin <> encode_expected_delay(seconds)

      {:encapsulation_format_info, security_classes}, bin ->
        bin <> EncapsulationFormatInfo.to_binary(security_classes)

      :multicast_addressing, bin ->
        bin <> <<0x05, 0x00>>

      :installation_and_maintenance_get, bin ->
        bin <> <<0x02, 0x00>>

      # We don't ever need to send this to Z/IP Gateway even if it's specified
      {:installation_and_maintenance_report, _}, bin ->
        bin

      extension, bin ->
        Logger.warning(
          "[Grizzly] Encoding not supported for Z/IP Packet header extension: #{inspect(extension)}"
        )

        bin
    end)
  end

  defp parse_extension(<<0x01, 0x03, seconds::24, rest::binary>>, extensions) do
    {[{:expected_delay, seconds} | extensions], rest}
  end

  defp parse_extension(<<0x02, 0x00, rest::binary>>, extensions),
    do: {[:installation_and_maintenance_get | extensions], rest}

  defp parse_extension(<<0x03, length, rest::binary>> = report, extensions) do
    <<_::binary-size(length), rest::binary>> = rest

    {[
       {:installation_and_maintenance_report,
        InstallationAndMaintenanceReport.from_binary(report)}
       | extensions
     ], rest}
  end

  defp parse_extension(
         <<0x84, 0x02, security_to_security, _::7, crc16::1, rest::binary>>,
         extensions
       ) do
    security_to_security = EncapsulationFormatInfo.security_from_byte(security_to_security)

    crc16_bool = if crc16 == 1, do: true, else: false

    {[
       {:encapsulation_format_info, EncapsulationFormatInfo.new(security_to_security, crc16_bool)}
       | extensions
     ], rest}
  end

  defp parse_extension(<<0x05, 0x00, rest::binary>>, extensions) do
    {[:multicast_addressing | extensions], rest}
  end

  defp encode_expected_delay(expected_delay) do
    <<0x01, 0x03, expected_delay::24>>
  end
end
