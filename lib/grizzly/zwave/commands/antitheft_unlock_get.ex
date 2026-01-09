defmodule Grizzly.ZWave.Commands.AntitheftUnlockGet do
  @moduledoc """
  This command is used to request the locked/unlocked state of the node.

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
