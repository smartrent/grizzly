defmodule Grizzly.ZWave.Commands.ApplicationNodeInfoGet do
  @moduledoc """
  Get the node information frame of for the Z/IP Gateway controller

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, keyword()} | {:error, DecodeError.t()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
