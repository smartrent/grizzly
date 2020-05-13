defmodule Grizzly.ZWave.Commands.ThermostatFanModeGet do
  @moduledoc """
  This module implements command THERMOSTAT_FAN_MODE_GET of the COMMAND_CLASS_THERMOSTAT_FAN_MODE command class

  This command is used to request the fan mode

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatFanMode

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_fan_mode_get,
      command_byte: 0x02,
      command_class: ThermostatFanMode,
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
