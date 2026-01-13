defmodule Grizzly.ZWave.Commands.UserChecksumGet do
  @moduledoc """
  UserChecksumGet is used to request the checksum for a specific user and their
  associated credentials at the receiving node.

  ## Parameters

  * `:user_id` - the ID of the user to get the checksum for (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:user_id, 1..0xFFFF}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    user_id = Command.param!(command, :user_id)
    <<user_id::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<user_id::16>>) do
    {:ok, [user_id: user_id]}
  end
end
