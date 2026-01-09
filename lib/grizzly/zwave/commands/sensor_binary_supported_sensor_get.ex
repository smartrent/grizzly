defmodule Grizzly.ZWave.Commands.SensorBinarySupportedSensorGet do
  @moduledoc """
  Requests the list of supported sensor types.
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
