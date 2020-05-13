defmodule Grizzly.ZWave.Commands.ThermostatModeGet do
  @moduledoc """
  This module implements command THERMOSTAT_MODE_GET of the command class COMMAND_CLASS_THERMOSTAT_MODE.

  The command is used to request the current mode set at the receiving node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatMode

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_mode_get,
      command_byte: 0x02,
      command_class: ThermostatMode,
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
