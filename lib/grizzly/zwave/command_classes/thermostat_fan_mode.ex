defmodule Grizzly.ZWave.CommandClasses.ThermostatFanMode do
  @moduledoc """
  "ThermostatFanMode" Command Class

  What type of commands does this command class support?
  """

  @type mode :: :auto_low | :low | :auto_high | :high

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @impl true
  def byte(), do: 0x44

  @impl true
  def name(), do: :thermostat_fan_mode

  @spec encode_mode(mode) :: byte
  def encode_mode(:auto_low), do: 0x00
  def encode_mode(:low), do: 0x01
  def encode_mode(:auto_high), do: 0x02
  def encode_mode(:high), do: 0x03

  @spec decode_mode(byte) :: {:ok, mode} | {:error, DecodeError.t()}
  def decode_mode(0x00), do: {:ok, :auto_low}
  def decode_mode(0x01), do: {:ok, :low}
  def decode_mode(0x02), do: {:ok, :auto_high}
  def decode_mode(0x03), do: {:ok, :high}

  def decode_mode(byte),
    do: {:error, %DecodeError{value: byte, param: :mode, command: :thermostat_fan_mode}}
end
