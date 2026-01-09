defmodule Grizzly.ZWave.Commands.DoorLockCapabilitiesGet do
  @moduledoc """
  This command is used to request the Door Lock capabilities of a supporting node.

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
