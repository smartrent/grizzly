defmodule Grizzly.ZWave.Commands.MultiChannelAssociationGroupingsGet do
  @moduledoc """
  This command is used to request the number of association groups that this node supports.

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
