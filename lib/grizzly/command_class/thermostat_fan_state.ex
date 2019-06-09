defmodule Grizzly.CommandClass.ThermostatFanState do
  @type state ::
          :off
          | :running
          | :running_high
          | :running_medium
          | :circulation_mode
          | :humidity_circulation_mode
          | :right_left_circulation_mode
          | :up_down_circulation_mode
          | :quite_circulation_mode

  @spec decode_state(0..8) :: state
  def decode_state(0), do: :off
  def decode_state(1), do: :running
  def decode_state(2), do: :running_high
  def decode_state(3), do: :running_medium
  def decode_state(4), do: :circulation_mode
  def decode_state(5), do: :humidity_circulation_mode
  def decode_state(6), do: :right_left_circulation_mode
  def decode_state(7), do: :up_down_circulation_mode
  def decode_state(8), do: :quite_circulation_mode
end
