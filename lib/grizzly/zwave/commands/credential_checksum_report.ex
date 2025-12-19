defmodule Grizzly.ZWave.Commands.CredentialChecksumReport do
  @moduledoc """
  CredentialChecksumReport is used to report the checksum for all credentials of a
  specific type currently set at the sending node.

  ## Parameters

  * `:credential_type` - the type of credential to report the checksum for (required)
  * `:checksum` - the reported checksum value (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

  @type param :: {:credential_type, UserCredential.credential_type()} | {:checksum, 0..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :credential_checksum_report,
      command_byte: 0x19,
      command_class: UserCredential,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    credential_type = Command.param!(command, :credential_type)
    checksum = Command.param!(command, :checksum)

    <<UserCredential.encode_credential_type(credential_type), checksum::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<credential_type::8, checksum::16>>) do
    {:ok,
     [
       credential_type: UserCredential.decode_credential_type(credential_type),
       checksum: checksum
     ]}
  end
end
