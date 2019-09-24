defmodule Grizzly.CommandClass.ThermostatMode do
  @moduledoc """
  """

  @type mode :: :off | :heat | :cool | :auto | byte

  @spec encode_mode(mode) :: {:ok, byte} | {:error, :invalid_arg, any()}
  def encode_mode(:off), do: {:ok, 0x00}
  def encode_mode(:heat), do: {:ok, 0x01}
  def encode_mode(:cool), do: {:ok, 0x02}
  def encode_mode(:auto), do: {:ok, 0x03}
  def encode_mode(byte) when byte in 0..255, do: {:ok, byte}
  def encode_mode(other), do: {:error, :invalid_arg, other}

  @spec decode_mode(byte) :: mode
  def decode_mode(0x00), do: :off
  def decode_mode(0x01), do: :heat
  def decode_mode(0x02), do: :cool
  def decode_mode(0x03), do: :auto
  def decode_mode(byte), do: byte
end
