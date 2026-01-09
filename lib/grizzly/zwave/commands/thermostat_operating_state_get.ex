defmodule Grizzly.ZWave.Commands.ThermostatOperatingStateGet do
  @moduledoc """
  This module implement command THERMOSTAT_OPERATING_STATE_GET of the
  COMMAND_CLASS_THERMOSTAT_OPERATING_STATE command class

  This command gets the operating state of the thermostat.

  Params: -none-

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
