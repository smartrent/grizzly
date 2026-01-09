defmodule Grizzly.ZWave.Commands.S0NonceGet do
  @moduledoc """
  This command is used to request an external nonce from the receiving node.
  """
  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
