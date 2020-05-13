defmodule Grizzly.ZWave.Commands.ThermostatSetpointGet do
  @moduledoc """
  This module implements command THERMOSTAT_SETPOINT_GET of the COMMAND_CLASS_THERMOSTAT_SETPOINT command class.

  This command is used to request the target value for a given setpoint type.

  Params:

    * `:type` - one of :heating | :cooling | :furnace | :dry_air | :moist_air | :auto_changeover

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param :: {:type | ThermostatSetpoint.type()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_get,
      command_byte: 0x02,
      command_class: ThermostatSetpoint,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    type_byte = ThermostatSetpoint.encode_type(Command.param!(command, :type))
    <<0x00::size(4), type_byte::size(4)>>
  end

  @impl true
  def decode_params(<<0x00::size(4), type_byte::size(4)>>) do
    with {:ok, type} <- ThermostatSetpoint.decode_type(type_byte) do
      {:ok, [type: type]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
