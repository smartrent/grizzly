defmodule Grizzly.ZWave.Commands.ApplicationRejectedRequest do
  @moduledoc """
  This command is used to instruct a node that the command was rejected by the
  application in the receiving node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    # "status" must always be 0
    <<0x00>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
