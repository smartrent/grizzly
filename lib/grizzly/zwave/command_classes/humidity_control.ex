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

  def encode_mode(:off), do: 0x00
  def encode_mode(:humidify), do: 0x01
  def encode_mode(:dehumidify), do: 0x02
  def encode_mode(:auto), do: 0x03

  def decode_mode(0x00), do: :off
  def decode_mode(0x01), do: :humidify
  def decode_mode(0x02), do: :dehumidify
  def decode_mode(0x03), do: :auto

  def decode_mode(v) do
    Logger.error("[Grizzly] Unknown humidity control operating mode: #{v}")
    :unknown
  end

  def encode_operating_state(:idle), do: 0x00
  def encode_operating_state(:humidifying), do: 0x01
  def encode_operating_state(:dehumidifying), do: 0x02

  def decode_operating_state(0x00), do: :idle
  def decode_operating_state(0x01), do: :humidifying
  def decode_operating_state(0x02), do: :dehumidifying

  def decode_operating_state(v) do
    Logger.error("[Grizzly] Unknown humidity control operating state: #{v}")
    :unknown
  end

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
