defmodule Grizzly.ZWave.Commands.CredentialChecksumGet do
  @moduledoc """
  CredentialChecksumGet is used to request the checksum for all credentials of a
  specific type currently set at the receiving node.

  ## Parameters

  * `:credential_type` - the type of credential to get the checksum for (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

  @type param :: {:credential_type, UserCredential.credential_type()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :credential_checksum_get,
      command_byte: 0x18,
      command_class: UserCredential,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    credential_type = Command.param!(command, :credential_type)
    <<UserCredential.encode_credential_type(credential_type)>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<credential_type::8>>) do
    {:ok, [credential_type: UserCredential.decode_credential_type(credential_type)]}
  end
end
