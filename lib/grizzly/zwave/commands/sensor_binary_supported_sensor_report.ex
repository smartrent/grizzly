defmodule Grizzly.ZWave.Commands.SensorBinarySupportedSensorReport do
  @moduledoc """
  Advertises a supporting node's supported sensor types.

  ## Params

  * `:sensor_types` - list of supported sensor types
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SensorBinary

  # See Grizzly.ZWave.CommandClasses.SensorBinary for the full list of sensor type values
  @type sensor_type :: atom
  @type param :: {:sensor_types, [sensor_type]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    sensor_types = Command.param!(command, :sensor_types)
    SensorBinary.encode_sensor_types(sensor_types)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, binary) do
    SensorBinary.decode_sensor_types(binary)
  end
end
