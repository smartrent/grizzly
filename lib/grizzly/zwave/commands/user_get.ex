defmodule Grizzly.ZWave.Commands.UserGet do
  @moduledoc """
  UserGet is used to request a specific user ID from the receiving node.

  ## Parameters

  * `:user_id` - the ID of the user to get (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.UserCredential

  @type param :: {:user_id, 1..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_get,
      command_byte: 0x06,
      command_class: UserCredential,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_id = Command.param!(command, :user_id)
    <<user_id::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<user_id::16>>) do
    {:ok, [user_id: user_id]}
  end
end
