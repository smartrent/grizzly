defmodule Grizzly.CommandClass.ThermostatMode do
  @moduledoc """
  """

  @type mode :: :off | :heat | :cool | :auto | byte

  @spec mode_to_byte(mode) :: byte
  def mode_to_byte(:off), do: 0x00
  def mode_to_byte(:heat), do: 0x01
  def mode_to_byte(:cool), do: 0x02
  def mode_to_byte(:auto), do: 0x03
  def mode_to_byte(byte) when byte in 0..255, do: byte

  @spec mode_from_byte(byte) :: mode
  def mode_from_byte(0x00), do: :off
  def mode_from_byte(0x01), do: :heat
  def mode_from_byte(0x02), do: :cool
  def mode_from_byte(0x03), do: :auto
  def mode_from_byte(byte), do: byte
end
