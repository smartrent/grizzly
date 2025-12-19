defmodule Grizzly.ZWave.CommandClasses.Mailbox do
  @moduledoc """
  Mailbox Command Class

  See Sections 5.2.3 and 5.2.4 of the Z-Wave Specification.
  """

  @behaviour Grizzly.ZWave.CommandClass

  import Bitwise

  @type mode :: :disabled | :service | :proxy
  @type supported_mode :: :service | :proxy

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x69

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :mailbox

  @spec encode_mode(mode()) :: 0..2
  def encode_mode(:disabled), do: 0x00
  def encode_mode(:service), do: 0x01
  def encode_mode(:proxy), do: 0x02

  @spec decode_mode(0..2) :: mode()
  def decode_mode(0x00), do: :disabled
  def decode_mode(0x01), do: :service
  def decode_mode(0x02), do: :proxy

  @doc """
  Encodes a list of supported modes into a single byte.

  ## Examples

      iex> encode_supported_modes([:service, :proxy])
      3
      iex> encode_supported_modes([:proxy])
      2
      iex> encode_supported_modes([:service])
      1
      iex> encode_supported_modes([])
      0
  """
  @spec encode_supported_modes([supported_mode()]) :: 0..3
  def encode_supported_modes(modes) do
    modes
    |> Enum.map(&encode_mode/1)
    |> Enum.reduce(0, fn mode, acc -> acc ||| mode end)
  end

  @doc """
  Encodes a list of supported modes from a single byte.

  ## Examples

      iex> decode_supported_modes(3)
      [:service, :proxy]
      iex> decode_supported_modes(2)
      [:proxy]
      iex> decode_supported_modes(1)
      [:service]
      iex> decode_supported_modes(0)
      []
  """
  @spec decode_supported_modes(0..3) :: [supported_mode()]
  def decode_supported_modes(3), do: [:service, :proxy]
  def decode_supported_modes(2), do: [:proxy]
  def decode_supported_modes(1), do: [:service]
  def decode_supported_modes(0), do: []
end
