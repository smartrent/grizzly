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

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :thermostat_setback_get,
      command_byte: 0x02,
      command_class: ThermostatSetback,
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
