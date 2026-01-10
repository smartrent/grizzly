defmodule Grizzly.ZWave.CommandClasses.HumidityControlMode do
  @moduledoc """
  HumidityControlMode
  """

  require Logger

  @type mode :: :off | :humidify | :dehumidify | :auto

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
end
