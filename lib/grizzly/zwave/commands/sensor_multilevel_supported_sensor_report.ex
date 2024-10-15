defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorReport do
  @moduledoc """
  This module implements command SENSOR_MULTILEVEL_SUPPORTED_SENSOR_REPORT of the COMMAND_CLASS_SENSOR_MULTILEVEL command class.
  This command is used to advertise the supported Sensor Types by a supporting node.

  Params:

    * `:sensor_types` - `list  of :temperature or :illuminance or :power or :humidity` etc. (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SensorMultilevel

  # See Grizzly.ZWave.CommandClasses.SensorMultilevel for the full list of sensor type values
  @type sensor_type :: atom
  @type param :: {:sensor_types, [sensor_type]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sensor_multilevel_supported_sensor_report,
      command_byte: 0x02,
      command_class: SensorMultilevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    sensor_types = Command.param!(command, :sensor_types)
    SensorMultilevel.encode_sensor_types(sensor_types)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(binary) do
    {:ok, [sensor_types: SensorMultilevel.decode_sensor_types(binary)]}
  end
end
