defmodule Grizzly.CommandClass.Basic do
  @type value :: :on | :off
  @type value_byte :: 0x00 | 0xFF

  @spec encode_value(value) :: value_byte
  def encode_value(:on), do: 0xFF
  def encode_value(:off), do: 0x00
end
