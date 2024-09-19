defmodule Grizzly.ZWave.Commands.ThermostatSetpointGet do
  @moduledoc """
  This module implements command THERMOSTAT_SETPOINT_GET of the
  COMMAND_CLASS_THERMOSTAT_SETPOINT command class.

  This command is used to request the target value for a given setpoint type.

  Params:

    * `:type` - the setback type (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param() :: {:type, ThermostatSetpoint.type()}

  @impl Grizzly.ZWave.Command
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

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    type_byte = ThermostatSetpoint.encode_type(Command.param!(command, :type))
    <<0x00::4, type_byte::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<0x00::4, type::4>>) do
    {:ok, [type: ThermostatSetpoint.decode_type(type)]}
  end
end
