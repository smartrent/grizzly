defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorGet do
  @moduledoc """
  This module implements command SENSOR_MULTILEVEL_SUPPORTED_GET_SENSOR of command class COMMAND_CLASS_SENSOR_MULTILEVEL
  The command requests the list of supported sensor types.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SensorMultilevel

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :sensor_multilevel_supported_sensor_get,
      command_byte: 0x01,
      command_class: SensorMultilevel,
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
