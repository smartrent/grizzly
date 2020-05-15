defmodule Grizzly.ZWave.Commands.UserCodeUsersNumberGet do
  @moduledoc """
  This module implements the command USERS_NUMBER_GET from the COMMAND_CLASS_USER_CODE command class.

  This command is used to request the number of user codes supported

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :user_code_users_number_get,
      command_byte: 0x04,
      command_class: UserCode,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
