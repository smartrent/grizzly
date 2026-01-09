defmodule Grizzly.ZWave.Commands.S0NetworkKeyVerify do
  @moduledoc """
  This command is sent in response to a Network Key Set command. If the receiving
  node is able to decrypt this command, it indicates that the included node has
  successfully received the network key and has been securely included.
  """
  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
