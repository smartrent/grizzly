defmodule Grizzly.ZWave.Commands.AllUsersChecksumReport do
  @moduledoc """
  AllUsersChecksumReport is used to report the all users checksum at the sending node.

  ## Parameters

  * `:checksum` - the checksum covering the user ids, user types, active states,
    credential rules, usernames, username encodings, and all credentials currently set at the
    sending node (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

  @type param :: {:checksum, 0..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :all_users_checksum_report,
      command_byte: 0x15,
      command_class: UserCredential,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    checksum = Command.param!(command, :checksum)
    <<checksum::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<checksum::16>>) do
    {:ok, [checksum: checksum]}
  end
end
