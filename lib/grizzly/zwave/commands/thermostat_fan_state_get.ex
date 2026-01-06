defmodule Grizzly.ZWave.Commands.ThermostatFanStateGet do
  @moduledoc """
  This module implement command THERMOSTAT_FAN_STATE_GET of the
  COMMAND_CLASS_THERMOSTAT_FAN_STATE command class

  This command is used to request the fan operating state.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatFanState

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_fan_state_get,
      command_byte: 0x02,
      command_class: ThermostatFanState
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
