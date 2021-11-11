defmodule Grizzly.ZWave.Commands.ThermostatModeSupportedGet do
  @moduledoc """
  This module implements command THERMOSTAT_MODE_SUPPORTED_GET of the
  COMMAND_CLASS_THERMOSTAT_MODE command class.

  This command is used to query the thermostat's supported modes.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatMode

  @impl Grizzly.ZWave.Command
  @spec new([]) :: {:ok, Command.t()}
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_mode_supported_get,
      command_byte: 0x04,
      command_class: ThermostatMode,
      impl: __MODULE__
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
