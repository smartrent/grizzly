defmodule Grizzly.ZWave.Commands.AllUsersChecksumGet do
  @moduledoc """
  AllUsersChecksumGet is used to request the checksum covering the user ids, user
  types, active states, credential rules, usernames, username encodings, and all
  credentials currently set at the receiving node.
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
