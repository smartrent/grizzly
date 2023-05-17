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

  @impl Command
  @spec new([ThermostatSetpoint.param()]) :: {:ok, Command.t()}
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

  @impl Command
  def encode_params(command) do
    type_byte = Command.param!(command, :type) |> ThermostatSetpoint.encode_type()

    scale_byte = Command.param!(command, :scale) |> ThermostatSetpoint.encode_scale()

    value = Command.param!(command, :value)
    precision = precision(value)
    int_value = round(value * :math.pow(10, precision))
    byte_size = __bytes_needed__(int_value)

    <<0x00::size(4), type_byte::size(4), precision::size(3), scale_byte::size(2),
      byte_size::size(3), int_value::signed-size(byte_size)-unit(8)>>
  end

  @impl Command
  def decode_params(
        <<_::size(4), type_byte::size(4), precision::size(3), scale_byte::size(2),
          byte_size::size(3), int_value::signed-size(byte_size)-unit(8)>>
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

  def precision(value) when is_number(value) do
    case String.split("#{value}", ".") do
      [_] -> 0
      [_, dec] -> String.length(dec)
    end
  end

  def __bits_needed__(0), do: 1

  def __bits_needed__(int_value) do
    bits = ceil(:math.log2(abs(int_value)) + 1)

    # <<x::size(foo - 1)>> is only supported in Elixir >= 1.14
    rest_size = bits - 1
    <<msb::1, _rest::size(rest_size)>> = <<int_value::signed-size(bits)>>

    if msb == 1 && int_value > 0 do
      bits + 1
    else
      bits
    end
  end

  def __bytes_needed__(int_value) do
    bits = __bits_needed__(int_value)
    ceil(bits / 8)
  end
end
