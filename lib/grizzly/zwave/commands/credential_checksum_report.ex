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

  @type param :: {:credential_type, UserCredential.credential_type()} | {:checksum, 0..0xFFFF}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    credential_type = Command.param!(command, :credential_type)
    checksum = Command.param!(command, :checksum)

    <<UserCredential.encode_credential_type(credential_type), checksum::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<credential_type::8, checksum::16>>) do
    {:ok,
     [
       credential_type: UserCredential.decode_credential_type(credential_type),
       checksum: checksum
     ]}
  end
end
