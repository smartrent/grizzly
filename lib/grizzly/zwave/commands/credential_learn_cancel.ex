defmodule Grizzly.ZWave.Commands.CredentialLearnCancel do
  @moduledoc """
  CredentialLearnCancel is used to cancel the learning process of a credential.
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
  @spec decode_params(binary()) :: {:ok, [keyword()]} | {:error, DecodeError.t()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
