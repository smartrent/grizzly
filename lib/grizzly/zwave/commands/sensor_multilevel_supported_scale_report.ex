defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedScaleReport do
  @moduledoc """
  This module implements command SENSOR_MULTILEVEL_SUPPORTED_SCALE_REPORT of the COMMAND_CLASS_SENSOR_MULTILEVEL command class.
  This command is used to advertise the supported scales of a specified multilevel sensor type.

  ## Parameters

  * `:sensor_type` - `list  of :temperature or :illuminance or :power or :humidity` etc. (required)
  * `:supported_scales` - `list  of supported scales, e.g. [0, 1, 3]. (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, Encoding}
  alias Grizzly.ZWave.CommandClasses.SensorMultilevel

  @type param :: {:sensor_type, atom()} | {:supported_scales, [byte()]}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :sensor_multilevel_supported_scale_report,
      command_byte: 0x06,
      command_class: SensorMultilevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    sensor_type = Command.param(command, :sensor_type)
    supported_scales = Command.param(command, :supported_scales)
    sensor_type_byte = SensorMultilevel.encode_sensor_type(sensor_type)
    <<scales_bitmask>> = Encoding.encode_bitmask(supported_scales)
    <<sensor_type_byte, 0x00::4, scales_bitmask::4>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<sensor_type_byte, 0x00::4, scales_bitmask::4>>) do
    with {:ok, sensor_type} <- SensorMultilevel.decode_sensor_type(sensor_type_byte),
         supported_scales <- Encoding.decode_bitmask(<<scales_bitmask>>) do
      {:ok, [sensor_type: sensor_type, supported_scales: supported_scales]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
