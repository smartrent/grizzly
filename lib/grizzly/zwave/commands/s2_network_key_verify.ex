defmodule Grizzly.ZWave.Commands.S2NetworkKeyVerify do
  @moduledoc """
  This command is used by a joining node to verify a newly exchanged key with
  the including node.
  """
  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
