defmodule Grizzly.ZWave.CommandClasses.ThermostatOperatingState do
  @moduledoc """
  "ThermostatOperatingState" Command Class

  The Thermostat Operating State Command Class is used to obtain the operating state of the
  thermostat.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type state ::
          :idle
          | :heating
          | :cooling
          | :fan_only
          | :pending_heat
          | :pending_cool
          | :vent_economizer
          | :aux_heating
          | :heating_stage_2
          | :cooling_stage_2
          | :aux_heat_stage_2
          | :aux_heat_stage_3

  @impl true
  def byte(), do: 0x42

  @impl true
  def name(), do: :thermostat_operating_state

  @spec encode_state(state) :: byte
  def encode_state(:idle), do: 0x00
  def encode_state(:heating), do: 0x01
  def encode_state(:cooling), do: 0x02
  def encode_state(:fan_only), do: 0x03
  def encode_state(:pending_heat), do: 0x04
  def encode_state(:pending_cool), do: 0x05
  def encode_state(:vent_economizer), do: 0x06
  def encode_state(:aux_heating), do: 0x07
  def encode_state(:heating_stage_2), do: 0x08
  def encode_state(:cooling_stage_2), do: 0x09
  def encode_state(:aux_heat_stage_2), do: 0x0A
  def encode_state(:aux_heat_stage_3), do: 0x0B

  @spec decode_state(byte) :: {:ok, state} | {:error, DecodeError.t()}
  def decode_state(0x00), do: {:ok, :idle}
  def decode_state(0x01), do: {:ok, :heating}
  def decode_state(0x02), do: {:ok, :cooling}
  def decode_state(0x03), do: {:ok, :fan_only}
  def decode_state(0x04), do: {:ok, :pending_heat}
  def decode_state(0x05), do: {:ok, :pending_cool}
  def decode_state(0x06), do: {:ok, :vent_economizer}
  def decode_state(0x07), do: {:ok, :aux_heating}
  def decode_state(0x08), do: {:ok, :heating_stage_2}
  def decode_state(0x09), do: {:ok, :cooling_stage_2}
  def decode_state(0x0A), do: {:ok, :aux_heat_stage_2}
  def decode_state(0x0B), do: {:ok, :aux_heat_stage_3}

  def decode_state(byte),
    do: {:error, %DecodeError{value: byte, param: :state, command: :thermostat_operating_state}}
end
