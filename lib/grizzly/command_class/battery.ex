defmodule Grizzly.CommandClass.Battery do
  @type battery_level :: 0x00..0x64 | :low_battery_warning

  @spec decode_level(byte) :: battery_level
  def decode_level(0xFF), do: :low_battery_warning
  def decode_level(byte) when byte in 0x00..0x64, do: byte
end
