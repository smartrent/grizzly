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

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_fan_state_get,
      command_byte: 0x02,
      command_class: ThermostatFanState,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
