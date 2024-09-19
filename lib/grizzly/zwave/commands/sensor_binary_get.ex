defmodule Grizzly.ZWave.Commands.SensorBinaryGet do
  @moduledoc """
  What does this command do??

  Params:

    * `sensor_type` - the type of sensor (required)
               one of :general_purpose | :smoke | :co | :co2 | :heat | :water | :freeze | :tamper | :aux | :door_window | :tilt | :motion | :glass_break

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SensorBinary

  @type param :: {:sensor_type, SensorBinary.sensor_type()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sensor_binary_get,
      command_byte: 0x02,
      command_class: SensorBinary,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    sensor_type = Command.param!(command, :sensor_type)
    <<SensorBinary.encode_type(sensor_type)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<sensor_type_byte>>) do
    with {:ok, sensor_type} <- SensorBinary.decode_type(sensor_type_byte) do
      {:ok, [sensor_type: sensor_type]}
    else
      {:error, %DecodeError{} = error} ->
        error
    end
  end
end
