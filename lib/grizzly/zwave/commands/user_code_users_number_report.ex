defmodule Grizzly.ZWave.Commands.UserCodeUsersNumberReport do
  @moduledoc """
  Gets the number of supported user codes

  Params:

    * `supported_users` - the number of supported users

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type param :: {:supported_users, byte()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_code_users_number_report,
      command_byte: 0x05,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    <<Command.param!(command, :supported_users)>>
  end

  @impl true
  def decode_params(<<supported_users>>) do
    {:ok, [supported_users: supported_users]}
  end
end
