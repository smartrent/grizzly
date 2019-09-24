defmodule Grizzly.CommandClass.ThermostatSetpoint do
  @moduledoc """
  Module for generating the thermostat setpoint command
  """

  import Bitwise

  @typedoc """
  Type for the different setpoint types.

  Possible to send raw byte for a different setpoint type if
  needed. Otherwise, `:cooling` and `:heating` atoms are the
  explicitly supported setpoint types.
  """
  @type setpoint_type ::
          :cooling
          | :heating
          | :furnace
          | :dry_air
          | :moist_air
          | :auto_changeover
          | :energy_save_heating
          | :energy_save_cooling
          | :away_heating
          | :away_cooling
          | :full_power
          | byte
  @type setpoint_value :: non_neg_integer

  @spec encode_opts(opts :: keyword) :: {:ok, byte} | {:error, :invalid_arg, any()}
  def encode_opts(opts) do
    if Enum.all?(Keyword.values(opts), &(&1 in 0..255)) do
      encoded =
        opts
        |> Enum.reduce(0, fn {_, byte}, mask -> mask ||| byte end)

      {:ok, encoded}
    else
      {:error, :invalid_arg, opts}
    end
  end

  @spec encode_setpoint_type(setpoint_type) :: {:ok, byte} | {:error, :invalid_arg, any()}
  def encode_setpoint_type(:heating), do: {:ok, 0x01}
  def encode_setpoint_type(:cooling), do: {:ok, 0x02}
  def encode_setpoint_type(:furnace), do: {:ok, 0x07}
  def encode_setpoint_type(:dry_air), do: {:ok, 0x08}
  def encode_setpoint_type(:moist_air), do: {:ok, 0x09}
  def encode_setpoint_type(:auto_changeover), do: {:ok, 0x0A}
  def encode_setpoint_type(:energy_save_heating), do: {:ok, 0x0B}
  def encode_setpoint_type(:energy_save_cooling), do: {:ok, 0x0C}
  def encode_setpoint_type(:away_heating), do: {:ok, 0x0D}
  def encode_setpoint_type(:away_cooling), do: {:ok, 0x0E}
  def encode_setpoint_type(:full_power), do: {:ok, 0x0F}
  def encode_setpoint_type(0x00), do: {:error, :invalid_arg, 0x00}
  def encode_setpoint_type(byte) when byte in 0x03..0x06, do: {:error, :invalid_arg, byte}
  def encode_setpoint_type(byte), do: byte

  @spec decode_setpoint_type(byte) :: setpoint_type
  def decode_setpoint_type(0x01), do: :heating
  def decode_setpoint_type(0x02), do: :cooling
  def decode_setpoint_type(0x07), do: :furnace
  def decode_setpoint_type(0x08), do: :dry_air
  def decode_setpoint_type(0x09), do: :moist_air
  def decode_setpoint_type(0x0A), do: :auto_changeover
  def decode_setpoint_type(0x0B), do: :energy_save_heating
  def decode_setpoint_type(0x0C), do: :energy_save_cooling
  def decode_setpoint_type(0x0D), do: :away_heating
  def decode_setpoint_type(0x0E), do: :away_cooling
  def decode_setpoint_type(0x0F), do: :full_power
  def decode_setpoint_type(byte), do: byte
end
