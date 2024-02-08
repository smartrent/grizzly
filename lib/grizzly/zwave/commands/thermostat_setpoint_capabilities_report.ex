defmodule Grizzly.ZWave.Commands.ThermostatSetpointCapabilitiesReport do
  @moduledoc """
  This command is used advertise the supported setpoint value range for a given setpoint type.

  ## Parameters

  * `:type` - the setpoint type
  * `:min_scale` - scale of the minimum value
  * `:min_value` - minimum value
  * `:max_scale` - scale of the maximum value
  * `:max_value` - maximum value
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.CommandClasses.ThermostatSetpoint
  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatSetpoint

  @type param ::
          {:type, ThermostatSetpoint.type()}
          | {:min_scale, ThermostatSetpoint.scale()}
          | {:min_value, number()}
          | {:max_scale, ThermostatSetpoint.scale()}
          | {:max_value, number()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_setpoint_capabilities_report,
      command_byte: 0x0A,
      command_class: ThermostatSetpoint,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    type = Command.param!(command, :type)
    min_scale = Command.param!(command, :min_scale)
    min_value = Command.param!(command, :min_value)
    max_scale = Command.param!(command, :max_scale)
    max_value = Command.param!(command, :max_value)

    {min_int_value, min_precision, min_byte_size} = encode_zwave_float(min_value)
    {max_int_value, max_precision, max_byte_size} = encode_zwave_float(max_value)

    <<0::4, encode_type(type)::4, min_precision::3, encode_scale(min_scale)::2, min_byte_size::3,
      min_int_value::size(min_byte_size)-unit(8), max_precision::3, encode_scale(max_scale)::2,
      max_byte_size::3, max_int_value::size(max_byte_size)-unit(8)>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<_::4, type::4, min_precision::3, min_scale::2, min_byte_size::3,
          min_int_value::size(min_byte_size)-unit(8), max_precision::3, max_scale::2,
          max_byte_size::3, max_int_value::size(max_byte_size)-unit(8)>>
      ) do
    with {:ok, min_scale} <- decode_scale(min_scale),
         {:ok, max_scale} <- decode_scale(max_scale) do
      {:ok,
       [
         type: decode_type(type),
         min_scale: min_scale,
         min_value: decode_zwave_float(min_int_value, min_precision),
         max_scale: max_scale,
         max_value: decode_zwave_float(max_int_value, max_precision)
       ]}
    else
      {:error, %DecodeError{} = err} ->
        {:error, %{err | command: :thermostat_setpoint_capabilities_report}}
    end
  end
end
