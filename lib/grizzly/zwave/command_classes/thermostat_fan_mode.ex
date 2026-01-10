defmodule Grizzly.ZWave.CommandClasses.ThermostatFanMode do
  @moduledoc """
  "ThermostatFanMode" Command Class

  What type of commands does this command class support?
  """

  alias Grizzly.ZWave.DecodeError

  @type mode ::
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
          | :external_circulation

  @spec encode_mode(mode) :: byte
  def encode_mode(:auto_low), do: 0x00
  def encode_mode(:low), do: 0x01
  def encode_mode(:auto_high), do: 0x02
  def encode_mode(:high), do: 0x03
  def encode_mode(:auto_medium), do: 0x04
  def encode_mode(:medium), do: 0x05
  def encode_mode(:circulation), do: 0x06
  def encode_mode(:humidity_circulation), do: 0x07
  def encode_mode(:left_right), do: 0x08
  def encode_mode(:up_down), do: 0x09
  def encode_mode(:quiet), do: 0x0A
  def encode_mode(:external_circulation), do: 0x0B

  @spec decode_mode(byte) :: {:ok, mode} | {:error, DecodeError.t()}
  def decode_mode(0x00), do: {:ok, :auto_low}
  def decode_mode(0x01), do: {:ok, :low}
  def decode_mode(0x02), do: {:ok, :auto_high}
  def decode_mode(0x03), do: {:ok, :high}
  def decode_mode(0x04), do: {:ok, :auto_medium}
  def decode_mode(0x05), do: {:ok, :medium}
  def decode_mode(0x06), do: {:ok, :circulation}
  def decode_mode(0x07), do: {:ok, :humidity_circulation}
  def decode_mode(0x08), do: {:ok, :left_right}
  def decode_mode(0x09), do: {:ok, :up_down}
  def decode_mode(0x0A), do: {:ok, :quiet}
  def decode_mode(0x0B), do: {:ok, :external_circulation}

  def decode_mode(byte),
    do: {:error, %DecodeError{value: byte, param: :mode, command: :thermostat_fan_mode}}
end
