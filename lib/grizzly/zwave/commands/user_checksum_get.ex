defmodule Grizzly.ZWave.Commands.UserChecksumGet do
  @moduledoc """
  UserChecksumGet is used to request the checksum for a specific user and their
  associated credentials at the receiving node.

  ## Parameters

  * `:user_id` - the ID of the user to get the checksum for (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @type param :: {:user_id, 1..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_id = Command.param!(command, :user_id)
    <<user_id::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<user_id::16>>) do
    {:ok, [user_id: user_id]}
  end
end
