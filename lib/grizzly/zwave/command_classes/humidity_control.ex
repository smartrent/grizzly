defmodule Grizzly.ZWave.CommandClasses.HumidityControl do
  @moduledoc """
  Types and functions for the Humidity Control Mode, Operating State, and Setpoint
  command classes.
  """

  require Logger

  @type mode :: :off | :humidify | :dehumidify | :auto
  @type operating_state :: :idle | :humidifying | :dehumidifying
  @type setpoint_type :: :humidify | :dehumidify | :auto
  @type setpoint_scale :: :percentage | :absolute

  @spec encode_setpoint_type(setpoint_type()) :: 1 | 2 | 3
  def encode_setpoint_type(:humidify), do: 0x01
  def encode_setpoint_type(:dehumidify), do: 0x02
  def encode_setpoint_type(:auto), do: 0x03

  @spec decode_setpoint_type(byte()) :: setpoint_type() | :unknown
  def decode_setpoint_type(0x01), do: :humidify
  def decode_setpoint_type(0x02), do: :dehumidify
  def decode_setpoint_type(0x03), do: :auto

  def decode_setpoint_type(v) do
    Logger.error("[Grizzly] Unknown humidity control setpoint type: #{v}")
    :unknown
  end

  @spec encode_setpoint_scale(setpoint_scale()) :: 0 | 1
  def encode_setpoint_scale(:percentage), do: 0x00
  def encode_setpoint_scale(:absolute), do: 0x01

  @spec decode_setpoint_scale(byte()) :: setpoint_scale() | :unknown
  def decode_setpoint_scale(0x00), do: :percentage
  def decode_setpoint_scale(0x01), do: :absolute

  def decode_setpoint_scale(v) do
    Logger.error("[Grizzly] Unknown humidity control setpoint scale: #{v}")
    :unknown
  end
end
