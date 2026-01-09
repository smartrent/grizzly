defmodule Grizzly.ZWave.Commands.Hail do
  @moduledoc """
  Send an unsolicited Hail command to other devices on the network

  Params: None
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
