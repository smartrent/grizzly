defmodule Grizzly.ZWave.Commands.S2KexGet do
  @moduledoc """
  This command is used by an including node to query the joining node for
  supported KEX Schemes and ECDH profiles as well as which network keys the
  joining node intends to request.
  """
  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
