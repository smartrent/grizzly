defmodule Grizzly.ZWave.Commands.S0NetworkKeySet do
  @moduledoc """
  This command is used to send the S0 network key to a receiving node.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    Command.param!(command, :network_key)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<network_key::binary>>), do: {:ok, [network_key: network_key]}
end
