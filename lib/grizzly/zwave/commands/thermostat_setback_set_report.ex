defmodule Grizzly.ZWave.Commands.ThermostatSetbackSetReport do
  @moduledoc """
   This module implements command THERMOSTAT_SETBACK_SET of the
   COMMAND_CLASS_THERMOSTAT_SETBACK command class.

   This command is used to set the setback state of the thermostat.

  Params:

    * `:type` - the type the setback (required)
    * `:state` - the setback state (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatSetback
  alias Grizzly.ZWave.DecodeError

  @type param :: {:type, ThermostatSetback.type()} | {:state, ThermostatSetback.state()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    type_byte = Command.param!(command, :type) |> ThermostatSetback.encode_type()
    state_byte = Command.param!(command, :state) |> ThermostatSetback.encode_state()
    <<0x00::6, type_byte::2, state_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_::6, type_byte::2, state_byte>>) do
    with {:ok, type} <- ThermostatSetback.decode_type(type_byte),
         {:ok, state} <- ThermostatSetback.decode_state(state_byte) do
      {:ok, [type: type, state: state]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
