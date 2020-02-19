defmodule Grizzly.CommandClass.ThermostatSetback do
  @moduledoc """
  Module for generating the thermostat setback command
  """

  require Logger

  @typedoc """
  Type for the different setback types.
  """
  @type setback_type :: :no_override | :temporary_override | :permanent_override
  @type setback_state :: :frost_protection | :energy_saving_mode | integer

  @spec encode_setback_type(setback_type) :: {:ok, byte} | {:error, :invalid_arg, any()}
  def encode_setback_type(:no_override), do: {:ok, 0x00}
  def encode_setback_type(:temporary_override), do: {:ok, 0x01}
  def encode_setback_type(:permanent_override), do: {:ok, 0x02}
  def encode_setback_type(byte) when byte in 0..2, do: {:ok, byte}
  def encode_setback_type(other), do: {:error, :invalid_arg, other}

  @spec decode_setback_type(byte) :: setback_type
  def decode_setback_type(0x00), do: :no_override
  def decode_setback_type(0x01), do: :temporary_override
  def decode_setback_type(0x02), do: :permanent_override
  def decode_setback_type(byte), do: byte

  @spec encode_setback_state(setback_state) :: {:ok, byte} | {:error, :invalid_arg, 0x7B..0x7F}
  def encode_setback_state(:frost_protection), do: {:ok, 0x79}
  def encode_setback_state(:energy_saving_mode), do: {:ok, 0x7A}
  def encode_setback_state(state) when state in 0x7B..0x7E, do: {:error, :invalid_arg, state}
  def encode_setback_state(0x7F), do: {:error, :invalid_arg, 0x7F}

  def encode_setback_state(state) do
    <<num>> = <<state::8-integer-signed>>
    {:ok, num}
  end

  @spec decode_setback_state(byte) :: setback_state
  def decode_setback_state(0x79), do: :frost_protection
  def decode_setback_state(0x7A), do: :energy_saving_mode

  def decode_setback_state(val) when val not in 0x7B..0x7F do
    <<state::8-integer-signed>> = <<val>>
    state
  end

  def decode_setback_state(byte) do
    _ = Logger.warn("Unused or reserved setback state: #{byte}: Decoding to 0x00")
    0x00
  end
end
