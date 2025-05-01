defmodule Grizzly.ZWave.CommandClasses.HumidityControlSetpoint do
  @moduledoc """
  HumidityControlSetpoint Command Class
  """

  @behaviour Grizzly.ZWave.CommandClass

  require Logger

  @type type :: :humidify | :dehumidify | :auto
  @type scale :: :percentage | :absolute

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x64

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :humidity_control_setpoint

  @spec encode_type(type()) :: 1 | 2 | 3
  def encode_type(:humidify), do: 0x01
  def encode_type(:dehumidify), do: 0x02
  def encode_type(:auto), do: 0x03

  @spec decode_type(byte()) :: type() | :unknown
  def decode_type(0x01), do: :humidify
  def decode_type(0x02), do: :dehumidify
  def decode_type(0x03), do: :auto

  def decode_type(v) do
    Logger.error("[Grizzly] Unknown humidity control setpoint type: #{v}")
    :unknown
  end

  @spec encode_scale(scale()) :: 0 | 1
  def encode_scale(:percentage), do: 0x00
  def encode_scale(:absolute), do: 0x01

  @spec decode_scale(byte()) :: scale() | :unknown
  def decode_scale(0x00), do: :percentage
  def decode_scale(0x01), do: :absolute

  def decode_scale(v) do
    Logger.error("[Grizzly] Unknown humidity control setpoint scale: #{v}")
    :unknown
  end
end
