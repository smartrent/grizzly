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
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sensor_binary_supported_sensor_report,
      command_byte: 0x04,
      command_class: SensorBinary,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    sensor_types = Command.param!(command, :sensor_types)
    SensorBinary.encode_sensor_types(sensor_types)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(binary) do
    SensorBinary.decode_sensor_types(binary)
  end
end
