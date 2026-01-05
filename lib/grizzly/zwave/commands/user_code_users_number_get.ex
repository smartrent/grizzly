defmodule Grizzly.ZWave.Commands.UserCodeUsersNumberGet do
  @moduledoc """
  This module implements the command USERS_NUMBER_GET from the
  COMMAND_CLASS_USER_CODE command class.

  This command is used to request the number of user codes supported

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :user_code_users_number_get,
      command_byte: 0x04,
      command_class: UserCode
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
