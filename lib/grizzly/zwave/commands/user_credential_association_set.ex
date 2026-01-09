defmodule Grizzly.ZWave.Commands.UserCredentialAssociationSet do
  @moduledoc """
  UserCredentialAssociationSet is used to associate an existing credential with a
  different user.

  ## Parameters

  * `:credential_type` - the type of credential (required)
  * `:credential_slot` - the slot of the credential (required)
  * `:destination_user_id` - the ID of the new user the credential will belong to (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:credential_type, UserCredential.credential_type()}
          | {:credential_slot, 1..0xFFFF}
          | {:destination_user_id, 1..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    credential_type = Command.param!(command, :credential_type)
    credential_slot = Command.param!(command, :credential_slot)
    destination_user_id = Command.param!(command, :destination_user_id)

    <<UserCredential.encode_credential_type(credential_type), credential_slot::16,
      destination_user_id::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<credential_type, credential_slot::16, destination_user_id::16>>) do
    {:ok,
     [
       credential_type: UserCredential.decode_credential_type(credential_type),
       credential_slot: credential_slot,
       destination_user_id: destination_user_id
     ]}
  end
end
