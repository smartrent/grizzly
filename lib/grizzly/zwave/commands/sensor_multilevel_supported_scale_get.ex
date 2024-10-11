defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleGet do
  @moduledoc """
  This module implements command SENSOR_MULTILEVEL_SUPPORTED_SCALE_GET of command class COMMAND_CLASS_SENSOR_MULTILEVEL.
  This command is used to retrieve the supported scales of the specific sensor type from the Multilevel Sensor device.

  Params: * `:sensor_type` - `one of :temperature or :illuminance or :power or :humidity`

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SensorMultilevel

  @type param :: {:sensor_type, atom()}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :sensor_multilevel_supported_scale_get,
      command_byte: 0x03,
      command_class: SensorMultilevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    sensor_type = Command.param(command, :sensor_type)
    sensor_type_byte = SensorMultilevel.encode_sensor_type(sensor_type)
    <<sensor_type_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<sensor_type_byte>>) do
    case SensorMultilevel.decode_sensor_type(sensor_type_byte) do
      {:ok, sensor_type} ->
        {:ok, [sensor_type: sensor_type]}

      :error ->
        {:error,
         %DecodeError{
           value: sensor_type_byte,
           param: :sensor_type,
           command: :sensor_multilevel_supported_scale_get
         }}
    end
  end
end
