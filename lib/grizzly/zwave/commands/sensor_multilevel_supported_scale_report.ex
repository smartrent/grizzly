defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleReport do
  @moduledoc """
  This module implements command SENSOR_MULTILEVEL_SUPPORTED_SCALE_REPORT of the COMMAND_CLASS_SENSOR_MULTILEVEL command class.
  This command is used to advertise the supported scales of a specified multilevel sensor type.

  ## Parameters

  * `:sensor_type` - the type of sensor for which the scales are supported. (required)
  * `:supported_scales` - list of supported scales, e.g. [0, 1, 3]. (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SensorMultilevel
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding

  @type param :: {:sensor_type, atom()} | {:supported_scales, [byte()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    sensor_type = Command.param(command, :sensor_type)

    supported_scales =
      Command.param(command, :supported_scales)
      |> Enum.map(&SensorMultilevel.encode_sensor_scale(sensor_type, &1))

    sensor_type_byte = SensorMultilevel.encode_sensor_type(sensor_type)
    <<scales_bitmask>> = Encoding.encode_bitmask(supported_scales)
    <<sensor_type_byte, 0x00::4, scales_bitmask::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<sensor_type_byte, 0x00::4, scales_bitmask::4>>) do
    case SensorMultilevel.decode_sensor_type(sensor_type_byte) do
      {:ok, sensor_type} ->
        {:ok,
         [
           sensor_type: sensor_type,
           supported_scales:
             SensorMultilevel.decode_sensor_scales(sensor_type, <<scales_bitmask>>)
         ]}

      :error ->
        {:error,
         %DecodeError{
           value: sensor_type_byte,
           param: :sensor_type,
           command: :sensor_multilevel_supported_scale_report
         }}
    end
  end
end
