defmodule Grizzly.ZWave.Commands.UserCodeReport do
  @moduledoc """
  UserCodeReport reports on a user code

  Params:

    * `:user_id` - the id of the user code (required)
    * `:user_id_status` - the status if the user id slot (required)
    * `:user_code` - a 4 - 10 user code pin in string format (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type user_id_status :: :occupied | :available | :reserved_by_admin | :status_not_available

  @type param ::
          {:user_id, byte()} | {:user_id_status, user_id_status()} | {:user_code, String.t()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_id = Command.param!(command, :user_id)
    user_id_status = Command.param!(command, :user_id_status)
    user_code = Command.param!(command, :user_code)

    <<user_id, UserCode.user_id_status_to_byte(user_id_status)>> <> user_code
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<user_id, user_id_status_byte, user_code_binary::binary>>) do
    {:ok,
     [
       user_id: user_id,
       user_id_status: UserCode.user_id_status_from_byte(user_id_status_byte),
       user_code: String.trim_trailing(user_code_binary, <<0>>)
     ]}
  end
end
