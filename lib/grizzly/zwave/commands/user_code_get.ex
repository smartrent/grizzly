defmodule Grizzly.ZWave.Commands.UserCodeGet do
  @moduledoc """
  This module implements command USER_CODE_GET of the COMMAND_CLASS_USER_CODE
  command class.

  This command is used to request the User Code of a specific User Identifier.

  Params:

    * `user_id` - the user identifier, an integer between 1 and 255 (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:user_id, 1..255}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    user_id = Command.param!(command, :user_id)
    <<user_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<user_id>>) do
    {:ok, [user_id: user_id]}
  end
end
