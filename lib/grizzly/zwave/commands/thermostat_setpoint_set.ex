defmodule Grizzly.ZWave.Commands.ThermostatSetpointSet do
  @moduledoc """
  This module implements command THERMOSTAT_SETPOINT_SET of the
  COMMAND_CLASS_THERMOSTAT_SETPOINT command class.

  This command is used to set the target value for a given setpoint type.

  Params:

    * `:type` - the setpoint type (required)
    * `:scale` - the setpoint scale (required)
    * `:value` - the value of the setpoint (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding

  @impl Command
  @spec new([ThermostatSetpoint.param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_set,
      command_byte: 0x01,
      command_class: ThermostatSetpoint,
      params: params
    }

    {:ok, command}
  end

  @impl Command
  def encode_params(command) do
    type_byte = Command.param!(command, :type) |> ThermostatSetpoint.encode_type()
    scale_byte = Command.param!(command, :scale) |> ThermostatSetpoint.encode_scale()
    value = Command.param!(command, :value)

    {int_value, precision, byte_size} = Encoding.encode_zwave_float(value)

    <<0x00::4, type_byte::4, precision::3, scale_byte::2, byte_size::3,
      int_value::signed-size(byte_size)-unit(8)>>
  end

  @impl Command
  def decode_params(
        <<_::4, type_byte::4, precision::3, scale_byte::2, byte_size::3,
          int_value::signed-size(byte_size)-unit(8)>>
      ) do
    type = ThermostatSetpoint.decode_type(type_byte)

    case ThermostatSetpoint.decode_scale(scale_byte) do
      {:ok, scale} ->
        value = Encoding.decode_zwave_float(int_value, precision)
        {:ok, [type: type, scale: scale, value: value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
