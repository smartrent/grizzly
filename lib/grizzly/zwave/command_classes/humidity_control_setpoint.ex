defmodule Grizzly.ZWave.CommandClasses.HumidityControlSetpoint do
  @moduledoc """
  HumidityControlSetpoint Command Class
  """

  @behaviour Grizzly.ZWave.CommandClass

  require Logger

  @type type :: :humidifier | :dehumidifier | :auto
  @type scale :: :percentage | :absolute

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x64

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :humidity_control_setpoint

  @spec encode_type(:auto | :dehumidifier | :humidifier) :: 1 | 2 | 3
  def encode_type(:humidifier), do: 0x01
  def encode_type(:dehumidifier), do: 0x02
  def encode_type(:auto), do: 0x03

  @spec decode_type(byte()) :: :auto | :dehumidifier | :humidifier | :unknown
  def decode_type(0x01), do: :humidifier
  def decode_type(0x02), do: :dehumidifier
  def decode_type(0x03), do: :auto

  def decode_type(v) do
    Logger.error("[Grizzly] Unknown humidity control setpoint type: #{v}")
    :unknown
  end

  @spec encode_scale(:absolute | :percentage) :: 0 | 1
  def encode_scale(:percentage), do: 0x00
  def encode_scale(:absolute), do: 0x01

  @spec decode_scale(byte()) :: :absolute | :percentage | :unknown
  def decode_scale(0x00), do: :percentage
  def decode_scale(0x01), do: :absolute

  def decode_scale(v) do
    Logger.error("[Grizzly] Unknown humidity control setpoint scale: #{v}")
    :unknown
  end
end
