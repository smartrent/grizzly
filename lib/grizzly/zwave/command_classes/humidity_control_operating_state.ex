defmodule Grizzly.ZWave.CommandClasses.HumidityControlOperatingState do
  @moduledoc """
  HumidityControlOperatingState
  """

  require Logger

  @type state :: :idle | :humidifying | :dehumidifying

  def encode_state(:idle), do: 0x00
  def encode_state(:humidifying), do: 0x01
  def encode_state(:dehumidifying), do: 0x02

  def decode_state(0x00), do: :idle
  def decode_state(0x01), do: :humidifying
  def decode_state(0x02), do: :dehumidifying

  def decode_state(v) do
    Logger.error("[Grizzly] Unknown humidity control operating state: #{v}")
    :unknown
  end
end
