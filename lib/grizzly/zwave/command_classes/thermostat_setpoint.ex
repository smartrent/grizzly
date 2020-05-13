defmodule Grizzly.ZWave.CommandClasses.ThermostatSetpoint do
  @moduledoc """
  "ThermostatSetpoint" Command Class

   The Thermostat Setpoint Command Class is used to configure setpoints for the modes supported by a
   thermostat.

  What type of commands does this command class support?
  """

  @type type :: :heating | :cooling | :furnace | :dry_air | :moist_air | :auto_changeover
  @type scale :: :celsius | :fahrenheit

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @impl true
  def byte(), do: 0x43

  @impl true
  def name(), do: :thermostat_setpoint

  @spec encode_type(type) :: byte
  def encode_type(:heating), do: 0x01
  def encode_type(:cooling), do: 0x02
  def encode_type(:furnace), do: 0x07
  def encode_type(:dry_air), do: 0x08
  def encode_type(:moist_air), do: 0x09
  def encode_type(:auto_changeover), do: 0x0A

  @spec decode_type(any) :: {:ok, type} | {:error, Grizzly.ZWave.DecodeError.t()}
  def decode_type(0x01), do: {:ok, :heating}
  def decode_type(0x02), do: {:ok, :cooling}
  def decode_type(0x07), do: {:ok, :furnace}
  def decode_type(0x08), do: {:ok, :dry_air}
  def decode_type(0x09), do: {:ok, :moist_air}
  def decode_type(0x0A), do: {:ok, :auto_changeover}

  def decode_type(byte),
    do: {:error, %DecodeError{value: byte, param: :type, command: :thermostat_setpoint}}

  @spec encode_scale(scale) :: byte
  def encode_scale(:celcius), do: 0x00
  def encode_scale(:fahrenheit), do: 0x01

  @spec decode_scale(byte) :: {:ok, scale} | {:error, %DecodeError{}}
  def decode_scale(0x00), do: {:ok, :celcius}
  def decode_scale(0x01), do: {:ok, :fahrenheit}

  def decode_scale(byte),
    do: {:error, %DecodeError{value: byte, param: :type, command: :thermostat_setpoint}}
end
