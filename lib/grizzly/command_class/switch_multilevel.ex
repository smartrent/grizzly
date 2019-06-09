defmodule Grizzly.CommandClass.SwitchMultilevel do
  @type switch_state :: :previous | :off | byte()

  @spec encode_switch_state(switch_state()) :: byte()
  def encode_switch_state(:previous), do: 0xFF
  def encode_switch_state(:off), do: 0x00
  def encode_switch_state(value) when value in 0..99, do: value

  def decode_switch_state(0x00), do: :off
  def decode_switch_state(0xFE), do: :unknown
  def decode_switch_state(value), do: value
end
