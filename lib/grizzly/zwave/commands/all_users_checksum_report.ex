defmodule Grizzly.ZWave.Commands.AllUsersChecksumReport do
  @moduledoc """
  AllUsersChecksumReport is used to report the all users checksum at the sending node.

  ## Parameters

  * `:checksum` - the checksum covering the user ids, user types, active states,
    credential rules, usernames, username encodings, and all credentials currently set at the
    sending node (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:checksum, 0..0xFFFF}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    checksum = Command.param!(command, :checksum)
    <<checksum::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<checksum::16>>) do
    {:ok, [checksum: checksum]}
  end
end
