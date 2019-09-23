defmodule Grizzly.CommandClass.ThermostatFanMode do
  @type thermostat_fan_mode ::
          :auto_low
          | :low
          | :auto_high
          | :high
          | :auto_medium
          | :medium
          | :circulation
          | :humidity_circulation
          | :left_right
          | :up_down
          | :quiet
  @type fan_mode_byte :: 0x00..0x0A

  @spec encode_thermostat_fan_mode(thermostat_fan_mode) ::
          {:ok, fan_mode_byte} | {:error, :invalid_arg, any()}
  def encode_thermostat_fan_mode(:auto_low), do: {:ok, 0x00}
  def encode_thermostat_fan_mode(:low), do: {:ok, 0x01}
  def encode_thermostat_fan_mode(:auto_high), do: {:ok, 0x02}
  def encode_thermostat_fan_mode(:high), do: {:ok, 0x03}
  def encode_thermostat_fan_mode(:auto_medium), do: {:ok, 0x04}
  def encode_thermostat_fan_mode(:medium), do: {:ok, 0x05}
  def encode_thermostat_fan_mode(:circulation), do: {:ok, 0x06}
  def encode_thermostat_fan_mode(:humidity_circulation), do: {:ok, 0x07}
  def encode_thermostat_fan_mode(:left_right), do: {:ok, 0x08}
  def encode_thermostat_fan_mode(:up_down), do: {:ok, 0x09}
  def encode_thermostat_fan_mode(:quiet), do: {:ok, 0x0A}
  def encode_thermostat_fan_mode(other), do: {:error, :invalid_arg, other}

  @spec decode_thermostat_fan_mode(fan_mode_byte) :: thermostat_fan_mode
  def decode_thermostat_fan_mode(0x00), do: :auto_low
  def decode_thermostat_fan_mode(0x01), do: :low
  def decode_thermostat_fan_mode(0x02), do: :auto_high
  def decode_thermostat_fan_mode(0x03), do: :high
  def decode_thermostat_fan_mode(0x04), do: :auto_medium
  def decode_thermostat_fan_mode(0x05), do: :medium
  def decode_thermostat_fan_mode(0x06), do: :circulation
  def decode_thermostat_fan_mode(0x07), do: :humidity_circulation
  def decode_thermostat_fan_mode(0x08), do: :left_right
  def decode_thermostat_fan_mode(0x09), do: :up_down
  def decode_thermostat_fan_mode(0x0A), do: :quiet
end
