defmodule Grizzly.ZWave.Commands.ThermostatSetbackGet do
  @moduledoc """
   This module implements command THERMOSTAT_SETBACK_GET of the command class
   COMMAND_CLASS_THERMOSTAT_SETBACK.

  This command is used to request the current setback state of the thermostat.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
