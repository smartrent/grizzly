defmodule Grizzly.ZWave.Commands.ThermostatOperatingStateGet do
  @moduledoc """
  This module implement command THERMOSTAT_OPERATING_STATE_GET of the COMMAND_CLASS_THERMOSTAT_OPERATING_STATE command class

  This command gets the operating state of the thermostat.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatOperatingState

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_operating_state_get,
      command_byte: 0x02,
      command_class: ThermostatOperatingState,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
