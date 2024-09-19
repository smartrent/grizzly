defmodule Grizzly.ZWave.CommandClasses.ThermostatFanState do
  @moduledoc """
  "ThermostatFanState" Command Class

  The Thermostat Fan State Command Class is used to obtain the fan operating state of the thermostat.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type state ::
          :off
          | :running
          | :running_high
          | :running_medium
          | :circulation
          | :humidity_circulation
          | :right_left_circulation
          | :up_down_circulation
          | :quiet_circulation

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x45

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :thermostat_fan_state

  @spec encode_state(state) :: byte
  def encode_state(:off), do: 0x00
  def encode_state(:running), do: 0x01
  def encode_state(:running_high), do: 0x02
  def encode_state(:running_medium), do: 0x03
  def encode_state(:circulation), do: 0x04
  def encode_state(:humidity_circulation), do: 0x05
  def encode_state(:right_left_circulation), do: 0x06
  def encode_state(:up_down_circulation), do: 0x07
  def encode_state(:quiet_circulation), do: 0x08

  @spec decode_state(any) :: {:ok, state} | {:error, Grizzly.ZWave.DecodeError.t()}
  def decode_state(0x00), do: {:ok, :off}
  def decode_state(0x01), do: {:ok, :running}
  def decode_state(0x02), do: {:ok, :running_high}
  def decode_state(0x03), do: {:ok, :running_medium}
  def decode_state(0x04), do: {:ok, :circulation}
  def decode_state(0x05), do: {:ok, :humidity_circulation}
  def decode_state(0x06), do: {:ok, :right_left_circulation}
  def decode_state(0x07), do: {:ok, :up_down_circulation}
  def decode_state(0x08), do: {:ok, :quiet_circulation}

  def decode_state(byte),
    do: {:error, %DecodeError{value: byte, param: :state, command: :thermostat_fan_state}}
end
