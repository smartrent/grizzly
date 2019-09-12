defmodule Grizzly.CommandClass.Basic do
  @type value :: :on | :off
  @type value_byte :: 0x00 | 0xFF

  @spec encode_value(value) :: {:ok, value_byte} | {:error, :invalid_arg, any()}
  def encode_value(:on), do: {:ok, 0xFF}
  def encode_value(:off), do: {:ok, 0x00}
  def encode_value(arg), do: {:error, :invalid_arg, arg}
end
