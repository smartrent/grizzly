defmodule Grizzly.ZWave.Commands.ThermostatOperatingStateReport do
  @moduledoc """
  This module implement command THERMOSTAT_OPERATING_STATE_REPORT (v1) of the COMMAND_CLASS_THERMOSTAT_OPERATING_STATE command class

  This command report the operating state of the thermostat.

  Params:

    * `:state` - the operating state, one of :idle | :heating | :cooling | :fan_only | :pending_heat | :pending_cool | :vent_economizer (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatOperatingState

  @type param :: {:state, ThermostatOperatingState.state()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_operating_state_report,
      command_byte: 0x03,
      command_class: ThermostatOperatingState,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    state_byte = Command.param!(command, :state) |> ThermostatOperatingState.encode_state()
    <<state_byte>>
  end

  @impl true
  def decode_params(<<state_byte>>) do
    with {:ok, state} <- ThermostatOperatingState.decode_state(state_byte) do
      {:ok, [state: state]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
