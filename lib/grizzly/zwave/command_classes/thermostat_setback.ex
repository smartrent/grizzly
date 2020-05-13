defmodule Grizzly.ZWave.CommandClasses.ThermostatSetback do
  @moduledoc """
  "ThermostatSetback" Command Class

  The Thermostat Setback Command Class is used to change the current state of a non-schedule setback
  thermostat.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type type :: :no_override | :temporary_override | :permanent_override
  @type state :: number | :frost_protection | :energy_saving

  @impl true
  def byte(), do: 0x47

  @impl true
  def name(), do: :thermostat_setback

  @spec encode_type(type) :: byte
  def encode_type(:no_override), do: 0x00
  def encode_type(:temporary_override), do: 0x01
  def encode_type(:permanent_override), do: 0x02

  @spec decode_type(byte) :: {:ok, type} | {:error, Grizzly.ZWave.DecodeError.t()}
  def decode_type(0x00), do: {:ok, :no_override}
  def decode_type(0x01), do: {:ok, :temporary_override}
  def decode_type(0x02), do: {:ok, :permanent_override}

  def decode_type(byte),
    do: {:error, %DecodeError{value: byte, param: :type, command: :thermostat_setback}}

  @spec encode_state(state) :: byte
  def encode_state(kelvins) when kelvins >= -12.8 and kelvins <= -1, do: round(256 + kelvins * 10)
  def encode_state(kelvins) when kelvins >= 0 and kelvins <= 12, do: round(kelvins * 10)
  def encode_state(:frost_protection), do: 0x79
  def encode_state(:energy_saving), do: 0x7A

  @spec decode_state(byte) :: {:ok, state} | {:error, Grizzly.ZWave.DecodeError.t()}
  def decode_state(byte) when byte in 0x80..0xFF, do: {:ok, (byte - 256) / 10}
  def decode_state(byte) when byte in 0x00..0x78, do: {:ok, byte / 10}
  def decode_state(0x79), do: {:ok, :frost_protection}
  def decode_state(0x7A), do: {:ok, :energy_saving}

  def decode_state(byte),
    do: {:error, %DecodeError{value: byte, param: :state, command: :thermostat_setback}}
end
