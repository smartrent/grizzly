defmodule Grizzly.ZWave.Commands.ThermostatSetbackGet do
  @moduledoc """
   This module implements command THERMOSTAT_SETBACK_GET of the command class
   COMMAND_CLASS_THERMOSTAT_SETBACK.

  This command is used to request the current setback state of the thermostat.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatSetback

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_setback_get,
      command_byte: 0x02,
      command_class: ThermostatSetback,
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
