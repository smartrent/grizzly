defmodule Grizzly.ZWave.Commands.ThermostatSetpointSupportedGet do
  @moduledoc """
  This module implements command THERMOSTAT_SETPOINT_SUPPORTED_GET of the
  COMMAND_CLASS_THERMOSTAT_SETPOINT command class.

  This command is used to query the supported setpoint types.
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
