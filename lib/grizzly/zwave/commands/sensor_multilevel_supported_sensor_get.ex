defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorGet do
  @moduledoc """
  This module implements command SENSOR_MULTILEVEL_SUPPORTED_GET_SENSOR of command class COMMAND_CLASS_SENSOR_MULTILEVEL
  The command requests the list of supported sensor types.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
