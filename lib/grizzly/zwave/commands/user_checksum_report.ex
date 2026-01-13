defmodule Grizzly.ZWave.Commands.UserChecksumReport do
  @moduledoc """
  UserChecksumReport is used to report the checksum for a specific user ID
  and their associated credentials at the sending node.

  ## Parameters

  * `:user_id` - the ID of the user to report the checksum for (required)
  * `:checksum` - the checksum value (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:user_id, 1..0xFFFF} | {:checksum, 0..0xFFFF}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    user_id = Command.param!(command, :user_id)
    checksum = Command.param!(command, :checksum)
    <<user_id::16, checksum::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<user_id::16, checksum::16>>) do
    {:ok, [user_id: user_id, checksum: checksum]}
  end
end
