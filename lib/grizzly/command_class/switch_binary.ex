defmodule Grizzly.CommandClass.SwitchBinary do
  @type switch_state :: :on | :off | :unknown
  @type switch_state_byte :: 0x00 | 0xFF | 0xFE | 1..99

  @spec encode_switch_state(switch_state) ::
          {:ok, switch_state_byte} | {:error, :invalid_arg, any()}
  def encode_switch_state(:on), do: {:ok, 0xFF}
  def encode_switch_state(:off), do: {:ok, 0x00}
  def encode_switch_state(:unknown), do: {:ok, 0xFE}
  def encode_switch_state(arg), do: {:error, :invalid_arg, arg}

  @spec decode_switch_state(switch_state_byte()) :: switch_state | 1..99
  def decode_switch_state(0x00), do: :off
  def decode_switch_state(0xFF), do: :on
  def decode_switch_state(0xFE), do: :unknown
  def decode_switch_state(value) when value in 1..99, do: value
end
