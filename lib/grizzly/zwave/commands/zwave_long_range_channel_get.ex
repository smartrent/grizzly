defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelGet do
  @moduledoc """
  Command to request the currently configured Z-Wave Long Range Channel

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def decode_params(_), do: {:ok, []}

  @impl Grizzly.ZWave.Command
  def encode_params(_), do: <<>>
end
