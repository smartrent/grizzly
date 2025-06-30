defmodule Grizzly.ZWave.Commands.UserChecksumReport do
  @moduledoc """
  UserChecksumReport is used to report the checksum for a specific user ID
  and their associated credentials at the sending node.

  ## Parameters

  * `:user_id` - the ID of the user to report the checksum for (required)
  * `:checksum` - the checksum value (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.UserCredential

  @type param :: {:user_id, 1..0xFFFF} | {:checksum, 0..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_checksum_report,
      command_byte: 0x17,
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
    checksum = Command.param!(command, :checksum)
    <<user_id::16, checksum::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<user_id::16, checksum::16>>) do
    {:ok, [user_id: user_id, checksum: checksum]}
  end
end
