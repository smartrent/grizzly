defmodule Grizzly.ZWave.Commands.ThermostatSetpointReport do
  @moduledoc """
  This module implements command THERMOSTAT_SETPOINT_REPORT of the COMMAND_CLASS_THERMOSTAT_SETPOINT command class.

  This command is used to advertise the target value for a given setpoint type

  Params:

    * `:type` - one of :heating | :cooling | :furnace | :dry_air | :moist_air | :auto_changeover (required)

    * `:scale` - temperature scale is used for the setpoint value, one of :celsius or :fahrenheit (required)

    * `:value` - the value of the setpoint

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param :: {:type, ThermostatSetpoint.type()} | {:scale, ThermostatSetpoint.scale()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
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
    with {:ok, type} <- ThermostatSetpoint.decode_type(type_byte),
         {:ok, scale} <- ThermostatSetpoint.decode_scale(scale_byte) do
      value = int_value / :math.pow(10, precision)
      {:ok, [type: type, scale: scale, value: value]}
    else
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
