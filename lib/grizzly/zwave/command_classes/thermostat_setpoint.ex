defmodule Grizzly.ZWave.CommandClasses.ThermostatSetpoint do
  @moduledoc """
  "ThermostatSetpoint" Command Class

   The Thermostat Setpoint Command Class is used to configure setpoints for the modes supported by a
   thermostat.

  What type of commands does this command class support?
  """

  @type type ::
          :na
          | :heating
          | :cooling
          | :furnace
          | :dry_air
          | :moist_air
          | :auto_changeover
          | :energy_save_heating
          | :energy_save_cooling
          | :away_heating
          | :away_cooling
          | :full_power

  @type scale :: :c | :f

  @typedoc "Shared parameters for ThermostatSetpointSet and ThermostatSetpointReport."
  @type param ::
          {:type, type()}
          | {:scale, scale()}
          | {:value, number()}

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x43

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :thermostat_setpoint

  @spec encode_type(type) :: byte
  def encode_type(:na), do: 0x00
  def encode_type(:heating), do: 0x01
  def encode_type(:cooling), do: 0x02
  def encode_type(:furnace), do: 0x07
  def encode_type(:dry_air), do: 0x08
  def encode_type(:moist_air), do: 0x09
  def encode_type(:auto_changeover), do: 0x0A
  def encode_type(:energy_save_heating), do: 0x0B
  def encode_type(:energy_save_cooling), do: 0x0C
  def encode_type(:away_heating), do: 0x0D
  def encode_type(:away_cooling), do: 0x0E
  def encode_type(:full_power), do: 0x0F

  @spec decode_type(byte()) :: type()
  def decode_type(0x01), do: :heating
  def decode_type(0x02), do: :cooling
  def decode_type(0x07), do: :furnace
  def decode_type(0x08), do: :dry_air
  def decode_type(0x09), do: :moist_air
  def decode_type(0x0A), do: :auto_changeover
  def decode_type(0x0B), do: :energy_save_heating
  def decode_type(0x0C), do: :energy_save_cooling
  def decode_type(0x0D), do: :away_heating
  def decode_type(0x0E), do: :away_cooling
  def decode_type(0x0F), do: :full_power
  def decode_type(_na_type), do: :na

  @spec encode_scale(scale) :: byte
  def encode_scale(:c), do: 0x00
  def encode_scale(:f), do: 0x01

  @spec decode_scale(byte) :: {:ok, scale} | {:error, DecodeError.t()}
  def decode_scale(0x00), do: {:ok, :c}
  def decode_scale(0x01), do: {:ok, :f}

  def decode_scale(byte),
    do: {:error, %DecodeError{value: byte, param: :type, command: :thermostat_setpoint}}
end
