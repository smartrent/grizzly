defmodule Grizzly.ZWave.Commands.UserCodeGet do
  @moduledoc """
  This module implements command USER_CODE_GET of the COMMAND_CLASS_USER_CODE command class.

  This command is used to request the User Code of a specific User Identifier.

  Params:

    * `user_id` - the user identifier, an integer between 1 and 255 (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type param :: {:user_id, 1..255}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_code_get,
      command_byte: 0x02,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    user_id = Command.param!(command, :user_id)
    <<user_id>>
  end

  @impl true
  def decode_params(<<user_id>>) do
    {:ok, [user_id: user_id]}
  end
end
