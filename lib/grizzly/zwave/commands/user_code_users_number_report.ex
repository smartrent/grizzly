defmodule Grizzly.ZWave.Commands.UserCodeUsersNumberReport do
  @moduledoc """
  Gets the number of supported user codes

  Params:

    * `supported_users` - the number of supported users (required)
    * `extended_supported_users` - if different, the total amount of supported users (required - v2 and above)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:supported_users, byte()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    extended_supported_users = Command.param(command, :extended_supported_users)

    if extended_supported_users == nil do
      <<Command.param!(command, :supported_users)>>
    else
      # Version 2
      <<Command.param!(command, :supported_users), extended_supported_users::16>>
    end
  end

  @impl Grizzly.ZWave.Command
  # Version 1
  def decode_params(<<supported_users>>) do
    {:ok, [supported_users: supported_users, extended_supported_users: 0]}
  end

  def decode_params(<<supported_users, extended_supported_users::16>>) do
    {:ok, [supported_users: supported_users, extended_supported_users: extended_supported_users]}
  end
end
