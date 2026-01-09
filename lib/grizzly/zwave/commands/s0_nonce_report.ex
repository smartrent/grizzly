defmodule Grizzly.ZWave.Commands.S0NonceReport do
  @moduledoc """
  This command is used to request an external nonce from the receiving node.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    nonce = Command.param!(command, :nonce)
    <<nonce::binary-size(8)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<nonce::binary-size(8)>>), do: {:ok, [nonce: nonce]}
end
