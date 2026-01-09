defmodule Grizzly.ZWave.Commands.ThermostatModeGet do
  @moduledoc """
  This module implements command THERMOSTAT_MODE_GET of the command class
  COMMAND_CLASS_THERMOSTAT_MODE.

  The command is used to request the current mode set at the receiving node.

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
