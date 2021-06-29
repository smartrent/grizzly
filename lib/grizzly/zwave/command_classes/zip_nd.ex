defmodule Grizzly.ZWave.CommandClasses.ZipND do
  @moduledoc """
  "ZipND" Command Class

  Z/IP ND Command Class builds on the same principles as IPv6 ND and is inspired by the frame
  formats.
  """

  @behaviour Grizzly.ZWave.CommandClass
  alias Grizzly.ZWave.DecodeError

  @type validity :: :information_ok | :information_obsolete | :information_not_found
  # e.g. "0306:0709:0803:0405:0708:0905:0607:0809"
  @type ipv6 :: String.t()

  @impl true
  def byte(), do: 0x58

  @impl true
  def name(), do: :zip_nd

  @doc "Convert validity to byte"
  @spec validity_to_byte(validity) :: byte
  def validity_to_byte(:information_ok), do: 0x00
  def validity_to_byte(:information_obsolete), do: 0x01
  def validity_to_byte(:information_not_found), do: 0x02

  @doc "Validity from byte"
  @spec validity_from_byte(byte) :: {:ok, validity} | {:error, %DecodeError{}}
  def validity_from_byte(0x00), do: {:ok, :information_ok}
  def validity_from_byte(0x01), do: {:ok, :information_obsolete}
  def validity_from_byte(0x02), do: {:ok, :information_not_found}
  def validity_from_byte(byte), do: {:error, %DecodeError{value: byte, param: :validity}}

  @doc "Decoce IPV6 address"
  @spec decode_ipv6_address(binary) :: {:ok, ipv6} | {:error, %DecodeError{}}
  def decode_ipv6_address(binary) do
    quartets = for(<<quartet::size(16) <- binary>>, do: Integer.to_string(quartet, 16))

    if Enum.count(quartets) == 8 do
      ipv6_address =
        quartets
        |> Enum.map(&String.pad_leading(&1, 4, "0"))
        |> Enum.join(":")

      {:ok, ipv6_address}
    else
      {:error, %DecodeError{value: binary, param: :ipv6_address}}
    end
  end

  @doc "Encode IPV6 address to binary"
  @spec encode_ipv6_address(ipv6) :: binary
  def encode_ipv6_address(ipv6) do
    String.split(ipv6, ":")
    |> Enum.reduce(<<>>, fn quartet, acc ->
      bytes = Integer.parse(quartet, 16) |> elem(0)
      acc <> <<bytes::size(16)>>
    end)
  end
end
