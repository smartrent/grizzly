defmodule Grizzly.ZWave.Commands.SensorMultilevelReport do
  @moduledoc """
  This module implements command COMMAND_CLASS_SENSOR_MULTILEVEL implements the SENSOR_MULTILEVEL_REPORT command class.
  This command is used to advertise a multilevel sensor reading.

  Params:  * `:sensor_type` - `one of :temperature or :illuminance or :power or :humidity` etc.(required)
           * `:scale` - ` 0..3 - identifies a unit of measurement` (required)
           * `:value` - the sensed, numerical value` (required)


  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SensorMultilevel

  # See Grizzly.ZWave.CommandClasses.SensorMultilevel for the full list of sensor type values
  @type sensor_type :: atom
  @type param ::
          {:sensor_type, sensor_type} | {:scale, 0..3} | {:precision, 0..3} | {:value, number}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sensor_multilevel_report,
      command_byte: 0x05,
      command_class: SensorMultilevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    sensor_type_byte = SensorMultilevel.encode_sensor_type(Command.param!(command, :sensor_type))
    scale = Command.param!(command, :scale)
    value = Command.param!(command, :value)
    precision = precision(value)
    int_value = round(value * :math.pow(10, precision))
    byte_size = ceil(:math.log2(int_value) / 8)

    <<sensor_type_byte, precision::size(3), scale::size(2), byte_size::size(3),
      int_value::size(byte_size)-unit(8)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<sensor_type_byte, precision::size(3), scale::size(2), size::size(3),
          int_value::size(size)-unit(8)>>
      ) do
    with {:ok, sensor_type} <- SensorMultilevel.decode_sensor_type(sensor_type_byte) do
      value = int_value / :math.pow(10, precision)
      {:ok, [sensor_type: sensor_type, scale: scale, value: value]}
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
