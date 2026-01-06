defmodule Grizzly.ZWave.Commands.ThermostatSetpointSupportedGet do
  @moduledoc """
  This module implements command THERMOSTAT_SETPOINT_SUPPORTED_GET of the
  COMMAND_CLASS_THERMOSTAT_SETPOINT command class.

  This command is used to query the supported setpoint types.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @impl Grizzly.ZWave.Command
  @spec new([]) :: {:ok, Command.t()}
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_setpoint_supported_get,
      command_byte: 0x04,
      command_class: ThermostatSetpoint
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
