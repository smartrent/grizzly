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

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param ::
          {:type, ThermostatSetpoint.type()}
          | {:scale, ThermostatSetpoint.scale()}
          | {:value, non_neg_integer()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_set,
      command_byte: 0x01,
      command_class: ThermostatSetpoint,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    type_byte = Command.param!(command, :type) |> ThermostatSetpoint.encode_type()

    scale_byte = Command.param!(command, :scale) |> ThermostatSetpoint.encode_scale()

    value = Command.param!(command, :value)
    precision = precision(value)
    int_value = round(value * :math.pow(10, precision))
    byte_size = ceil(:math.log2(int_value) / 8)

    <<0x00::size(4), type_byte::size(4), precision::size(3), scale_byte::size(2),
      byte_size::size(3), int_value::size(byte_size)-unit(8)>>
  end

  @impl true
  def decode_params(
        <<_::size(4), type_byte::size(4), precision::size(3), scale_byte::size(2),
          byte_size::size(3), int_value::size(byte_size)-unit(8)>>
      ) do
    type = ThermostatSetpoint.decode_type(type_byte)

    case ThermostatSetpoint.decode_scale(scale_byte) do
      {:ok, scale} ->
        value = int_value / :math.pow(10, precision)
        {:ok, [type: type, scale: scale, value: value]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp precision(value) when is_number(value) do
    case String.split("#{value}", ".") do
      [_] -> 0
      [_, dec] -> String.length(dec)
    end
  end
end
