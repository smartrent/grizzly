defmodule Grizzly.ZWave.Commands.SensorBinarySupportedSensorGet do
  @moduledoc """
  Requests the list of supported sensor types.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SensorBinary

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :sensor_binary_supported_sensor_get,
      command_byte: 0x01,
      command_class: SensorBinary,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
