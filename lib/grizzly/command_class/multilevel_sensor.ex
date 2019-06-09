defmodule Grizzly.CommandClass.MultilevelSensor do
  @moduledoc """
    Conversions for multilevel sensors.
  """

  @type level_type :: :temperature | :illuminance | :power | :humidity

  @spec decode_type(byte) :: level_type | byte
  def decode_type(type_num) do
    case type_num do
      1 -> :temperature
      3 -> :illuminance
      4 -> :power
      5 -> :humidity
      other -> other
    end
  end

  @spec encode_type(level_type) :: 1 | 3 | 4 | 5
  def encode_type(type) do
    case type do
      :temperature -> 0x1
      :illuminance -> 0x3
      :power -> 0x4
      :humidity -> 0x5
    end
  end
end
