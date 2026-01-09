defmodule Grizzly.ZWave.Commands.RssiGet do
  @moduledoc """
  This command is used to query the measured RSSI on the Z-Wave network from a node.

  Params: -none-

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
