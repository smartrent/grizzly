defmodule Grizzly.ZWave.Commands.UserCodeReport do
  @moduledoc """
  UserCodeReport reports on a user code

  Params:

    * `:user_id` - the id of the user code (required)
    * `:user_id_status` - the status if the user id slot (required)
    * `:user_code` - a 4 - 10 user code pin in string format (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type user_id_status :: :occupied | :available | :reserved_by_admin | :status_not_available

  @type param ::
          {:user_id, byte()} | {:user_id_status, user_id_status()} | {:user_code, String.t()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_code_report,
      command_byte: 0x03,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_id = Command.param!(command, :user_id)
    user_id_status = Command.param!(command, :user_id_status)
    user_code = Command.param!(command, :user_code)

    <<user_id, UserCode.user_id_status_to_byte(user_id_status)>> <> user_code
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<user_id, user_id_status_byte, user_code_binary::binary>>) do
    case UserCode.user_id_status_from_byte(user_id_status_byte) do
      {:ok, user_id_status} ->
        {:ok,
         [
           user_id: user_id,
           user_id_status: user_id_status,
           user_code: user_code_binary
         ]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
