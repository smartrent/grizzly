defmodule Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions do
  @moduledoc """
  Functions for working with the header extension in a Z/IP Packet.
  """

  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.{
    BinaryParser,
    EncapsulationFormatInfo,
    ExpectedDelay,
    InstallationAndMaintenanceReport
  }

  @type encapsulation_format_info :: :crc16 | EncapsulationFormatInfo.security()

  @type extension ::
          {:expected_delay, Command.delay_seconds()}
          | {:install_and_maintenance_report, list()}
          | :install_and_maintenance_get
          | {:encapsulation_format_info, [encapsulation_format_info()]}
          | :multicast_addressing

  @doc """
  Try to parse a binary string into `HeaderExtensions.t()`
  """
  @spec from_binary(binary()) :: [extension()]
  def from_binary(extensions) do
    extensions
    |> BinaryParser.from_binary()
    |> BinaryParser.parse(&parse_extension/1)
  end

  @spec to_binary([extension()]) :: binary()
  def to_binary(extensions) do
    Enum.reduce(extensions, <<>>, fn
      {:expected_delay, seconds}, bin ->
        bin <> ExpectedDelay.to_binary(seconds)

      {:encapsulation_format_info, security_classes}, bin ->
        bin <> EncapsulationFormatInfo.to_binary(security_classes)

      :multicast_addressing, bin ->
        bin <> <<0x05, 0x00>>

      :install_and_maintenance_get, bin ->
        bin <> <<0x02, 0x00>>

      # We don't ever need to send this to Z/IP Gateway even if it's specified
      {:install_and_maintenance_report, _}, bin ->
        bin
    end)
  end

  defp parse_extension(<<0x01, 0x03, seconds::3-unit(8), rest::binary>>) do
    {{:expected_delay, seconds}, rest}
  end

  defp parse_extension(<<0x02, 0x00, rest::binary>>),
    do: {:installation_and_maintenance_get, rest}

  defp parse_extension(<<0x03, length, rest::binary>> = report) do
    <<_::binary-size(length), rest::binary>> = rest

    {{:installation_and_maintenance_report, InstallationAndMaintenanceReport.from_binary(report)},
     rest}
  end

  defp parse_extension(
         <<0x84, 0x02, security_to_security, _::size(7), crc16::size(1), rest::binary>>
       ) do
    security_to_security =
      EncapsulationFormatInfo.security_to_security_from_byte(security_to_security)

    crc16_bool = if crc16 == 1, do: true, else: false

    {{:encapsulation_format_info, EncapsulationFormatInfo.new(security_to_security, crc16_bool)},
     rest}
  end

  defp parse_extension(<<0x05, 0x00, rest::binary>>) do
    {:multicast_addressing, rest}
  end
end
