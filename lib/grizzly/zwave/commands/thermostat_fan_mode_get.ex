defmodule Grizzly.ZWave.Commands.ThermostatFanModeGet do
  @moduledoc """
  This module implements command THERMOSTAT_FAN_MODE_GET of the
  COMMAND_CLASS_THERMOSTAT_FAN_MODE command class

  This command is used to request the fan mode.

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
