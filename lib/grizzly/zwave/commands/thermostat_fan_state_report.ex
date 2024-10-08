defmodule Grizzly.ZWave.Commands.ThermostatFanStateReport do
  @moduledoc """
   This module implements command THERMOSTAT_FAN_STATE_REPORT of the
   COMMAND_CLASS_THERMOSTAT_FAN_STATE command class.

   This command is used to report the fan operating state of the thermostat
   device.

  Params:

    * `:state` - the state of the fan (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatFanState

  @type param :: {:state, ThermostatFanState.state()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_fan_state_report,
      command_byte: 0x03,
      command_class: ThermostatFanState,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    state_byte = ThermostatFanState.encode_state(Command.param!(command, :state))
    <<0x00::4, state_byte::4>>
  end

  @impl Grizzly.ZWave.Command
  # version 1
  def decode_params(<<0x00::4, state_byte::4, _::binary>>) do
    with {:ok, state} <- ThermostatFanState.decode_state(state_byte) do
      {:ok, [state: state]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
