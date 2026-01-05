defmodule Grizzly.ZWave.Commands.ThermostatOperatingStateGet do
  @moduledoc """
  This module implement command THERMOSTAT_OPERATING_STATE_GET of the
  COMMAND_CLASS_THERMOSTAT_OPERATING_STATE command class

  This command gets the operating state of the thermostat.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatOperatingState

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_operating_state_get,
      command_byte: 0x02,
      command_class: ThermostatOperatingState
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
