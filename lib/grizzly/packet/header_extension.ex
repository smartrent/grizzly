defmodule Grizzly.Packet.HeaderExtension do
  @moduledoc """
  Functions for working with the header extension
  in a Z/IP Packet.
  """

  alias Grizzly.Packet.HeaderExtension.{
    ExpectedDelay,
    BinaryParser,
    InstallationAndMaintenanceGet,
    InstallationAndMaintenanceReport,
    EncapsulationFormatInfo
  }

  @type extension :: struct()

  @opaque t :: [extension]

  @doc """
  Given a header extension, get the expected delay in seconds
  """
  @spec get_expected_delay(t()) :: {:ok, ExpectedDelay.seconds()} | nil
  def get_expected_delay(extensions) do
    extensions
    |> Enum.filter(fn
      %ExpectedDelay{} -> true
      _ -> false
    end)
    |> List.first()
    |> maybe_get_expected_delay()
  end

  @doc """
  Make an expected delay from seconds
  """
  @spec expected_delay_from_seconds(ExpectedDelay.seconds()) :: ExpectedDelay.t()
  def expected_delay_from_seconds(seconds) do
    ExpectedDelay.new(seconds)
  end

  @doc """
  Try to parse a binary string into `HeaderExtension.t()`
  """
  @spec from_binary(binary()) :: t()
  def from_binary(extensions) do
    extensions
    |> BinaryParser.from_binary()
    |> BinaryParser.parse(&parse_extension/1)
  end

  defp parse_extension(<<0x01, 0x03, seconds::integer-size(3)-unit(8), rest::binary>>) do
    {ExpectedDelay.new(seconds), rest}
  end

  defp parse_extension(<<0x02, 0x00, rest::binary>>),
    do: {InstallationAndMaintenanceGet.new(), rest}

  defp parse_extension(<<0x03, length, rest::binary>> = report) do
    <<_::binary-size(length), rest::binary>> = rest

    {InstallationAndMaintenanceReport.from_binary(report), rest}
  end

  defp parse_extension(<<0x84, 0x02, security_to_security, crc16, rest::binary>>) do
    security_to_security =
      EncapsulationFormatInfo.security_to_security_from_byte(security_to_security)

    crc16 = EncapsulationFormatInfo.crc16_from_byte(crc16)
    {EncapsulationFormatInfo.new(security_to_security, crc16), rest}
  end

  defp parse_extension(<<0x05, 0x00, rest::binary>>) do
    {:multicast_addressing, rest}
  end

  defp maybe_get_expected_delay(nil), do: nil

  defp maybe_get_expected_delay(expected_delay) do
    {:ok, ExpectedDelay.get_seconds(expected_delay)}
  end
end
