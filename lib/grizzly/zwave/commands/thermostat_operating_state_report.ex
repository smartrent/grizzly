defmodule Grizzly.ZWave.Commands.ThermostatOperatingStateReport do
  @moduledoc """
  This module implement command THERMOSTAT_OPERATING_STATE_REPORT (v1) of the
  COMMAND_CLASS_THERMOSTAT_OPERATING_STATE command class

  This command report the operating state of the thermostat.

  Params:

    * `:state` - the operating state  (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatOperatingState
  alias Grizzly.ZWave.DecodeError

  @type param :: {:state, ThermostatOperatingState.state()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    state_byte = Command.param!(command, :state) |> ThermostatOperatingState.encode_state()
    <<state_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<state_byte>>) do
    with {:ok, state} <- ThermostatOperatingState.decode_state(state_byte) do
      {:ok, [state: state]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
