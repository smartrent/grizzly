defmodule Grizzly.CommandClass.SwitchBinary do
  @type switch_state :: :on | :off
  @type switch_state_byte :: 0x00 | 0xFF

  @spec encode_switch_state(switch_state) :: switch_state_byte
  def encode_switch_state(:on), do: 0xFF
  def encode_switch_state(:off), do: 0x00
end
