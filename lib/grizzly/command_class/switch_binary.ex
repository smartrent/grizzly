defmodule Grizzly.CommandClass.SwitchBinary do
  @type switch_state :: :on | :off
  @type switch_state_byte :: 0x00 | 0xFF

  @spec encode_switch_state(switch_state) ::
          {:ok, switch_state_byte} | {:error, :invalid_arg, any()}
  def encode_switch_state(:on), do: {:ok, 0xFF}
  def encode_switch_state(:off), do: {:ok, 0x00}
  def encode_switch_state(arg), do: {:error, :invalid_arg, arg}
end
