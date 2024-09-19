defmodule Grizzly.ZWave.CommandClasses.ThermostatMode do
  @moduledoc """
  "ThermostatMode" Command Class

  The Thermostat Mode Command Class is used to control which mode a thermostat operates.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type mode ::
          :off
          | :heat
          | :cool
          | :auto
          | :auxiliary
          | :resume_on
          | :fan
          | :furnace
          | :dry
          | :moist
          | :auto_changeover
          | :energy_heat
          | :energy_cool
          | :away
          | :full_power
          | :manufacturer_specific

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x40

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :thermostat_mode

  @spec encode_mode(mode) :: byte
  def encode_mode(:off), do: 0x00
  def encode_mode(:heat), do: 0x01
  def encode_mode(:cool), do: 0x02
  def encode_mode(:auto), do: 0x03
  def encode_mode(:auxiliary), do: 0x04
  def encode_mode(:resume_on), do: 0x05
  def encode_mode(:fan), do: 0x06
  def encode_mode(:furnace), do: 0x07
  def encode_mode(:dry), do: 0x08
  def encode_mode(:moist), do: 0x09
  def encode_mode(:auto_changeover), do: 0x0A
  def encode_mode(:energy_heat), do: 0x0B
  def encode_mode(:energy_cool), do: 0x0C
  def encode_mode(:away), do: 0x0D
  def encode_mode(:full_power), do: 0x0F
  def encode_mode(:manufacturer_specific), do: 0x1F

  @spec decode_mode(byte) :: {:ok, mode} | {:error, DecodeError.t()}
  def decode_mode(0x00), do: {:ok, :off}
  def decode_mode(0x01), do: {:ok, :heat}
  def decode_mode(0x02), do: {:ok, :cool}
  def decode_mode(0x03), do: {:ok, :auto}
  def decode_mode(0x04), do: {:ok, :auxiliary}
  def decode_mode(0x05), do: {:ok, :resume_on}
  def decode_mode(0x06), do: {:ok, :fan}
  def decode_mode(0x07), do: {:ok, :furnace}
  def decode_mode(0x08), do: {:ok, :dry}
  def decode_mode(0x09), do: {:ok, :moist}
  def decode_mode(0x0A), do: {:ok, :auto_changeover}
  def decode_mode(0x0B), do: {:ok, :energy_heat}
  def decode_mode(0x0C), do: {:ok, :energy_cool}
  def decode_mode(0x0D), do: {:ok, :away}
  def decode_mode(0x0F), do: {:ok, :full_power}
  def decode_mode(0x1F), do: {:ok, :manufacturer_specific}

  def decode_mode(byte),
    do: {:error, %DecodeError{value: byte, param: :mode, command: :thermostat_mode}}
end
