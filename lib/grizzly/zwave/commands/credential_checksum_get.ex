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

  @type param :: {:credential_type, UserCredential.credential_type()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    credential_type = Command.param!(command, :credential_type)
    <<UserCredential.encode_credential_type(credential_type)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<credential_type::8>>) do
    {:ok, [credential_type: UserCredential.decode_credential_type(credential_type)]}
  end
end
