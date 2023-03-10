defmodule Grizzly.ZWave.Commands.ThermostatSetpointReport do
  @moduledoc """
  This module implements command THERMOSTAT_SETPOINT_REPORT of the
  COMMAND_CLASS_THERMOSTAT_SETPOINT command class.

  This command is used to advertise the target value for a given
  setpoint type.

  Params:

    * `:type` - the setpoint type (required)
    * `:scale` - the setpoint scale (required)
    * `:value` - the value of the setpoint (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @impl Command
  @spec new([ThermostatSetpoint.param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_report,
      command_byte: 0x03,
      command_class: ThermostatSetpoint,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Command
  def encode_params(command) do
    type = Command.param!(command, :type)
    scale_byte = Command.param!(command, :scale) |> ThermostatSetpoint.encode_scale()
    value = encode_value(command, type)

    precision = precision(value)
    int_value = round(value * :math.pow(10, precision))
    byte_size = encode_size(type, int_value)

    <<0x00::size(4), ThermostatSetpoint.encode_type(type)::size(4), precision::size(3),
      scale_byte::size(2), byte_size::size(3), int_value::size(byte_size)-unit(8)>>
  end

  # The spec says when encoding `:na` type to force the size to 1 and the value to 0
  #
  #  "If this field [type] is set to 0x00 (N/A), it is RECOMMENDED to set the
  #   Size field to 1 and the Value field to 0."
  defp encode_value(_command, :na), do: 0
  defp encode_value(command, _other), do: Command.param!(command, :value)

  defp encode_size(:na, _value), do: 1
  defp encode_size(_type, value), do: ceil(:math.log2(value) / 8)

  @impl Command
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
