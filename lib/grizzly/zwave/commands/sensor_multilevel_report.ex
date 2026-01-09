defmodule Grizzly.ZWave.Commands.SensorMultilevelReport do
  @moduledoc """
  This module implements command COMMAND_CLASS_SENSOR_MULTILEVEL implements the
  SENSOR_MULTILEVEL_REPORT command class.

  This command is used to advertise a multilevel sensor reading.

  Params:
    * `:sensor_type` - one of `:temperature`, `:illuminance`, `:power`, or
      `:humidity` etc.(required)
    * `:scale` - `0..3` - identifies a unit of measurement (required)
    * `:value` - the sensed, numerical value (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SensorMultilevel
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding

  # See Grizzly.ZWave.CommandClasses.SensorMultilevel for the full list of sensor type values
  @type sensor_type :: atom
  @type param ::
          {:sensor_type, sensor_type} | {:scale, 0..3} | {:value, number}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    sensor_type = Command.param!(command, :sensor_type)
    sensor_type_byte = SensorMultilevel.encode_sensor_type(sensor_type)
    scale = Command.param!(command, :scale)
    scale_byte = SensorMultilevel.encode_sensor_scale(sensor_type, scale)

    value = Command.param!(command, :value)
    {int_value, precision, byte_size} = Encoding.encode_zwave_float(value)

    <<
      sensor_type_byte,
      precision::3,
      scale_byte::2,
      byte_size::3,
      int_value::signed-size(byte_size)-unit(8)
    >>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<
        sensor_type_byte,
        precision::3,
        scale::2,
        size::3,
        int_value::signed-size(size)-unit(8)
      >>) do
    case SensorMultilevel.decode_sensor_type(sensor_type_byte) do
      {:ok, sensor_type} ->
        value = Encoding.decode_zwave_float(int_value, precision)
        scale = SensorMultilevel.decode_sensor_scale(sensor_type, scale)
        {:ok, [sensor_type: sensor_type, scale: scale, value: value]}

      :error ->
        {:error,
         %DecodeError{
           value: sensor_type_byte,
           param: :sensor_type,
           command: :sensor_multilevel_report
         }}
    end
  end
end
