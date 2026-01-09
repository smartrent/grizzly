defmodule Grizzly.ZWave.Commands.CredentialSet do
  @moduledoc """
  CredentialSet is used to set a specific credential at the receiving node.

  ## Parameters

  * `:user_id` - the ID of the user for the credential (required)
  * `:credential_type` - the type of credential (required)
  * `:credential_slot` - the slot for the credential (required)
  * `:operation_type` - the type of operation for setting the credential (required)
    - `:add` - to add a new credential
    - `:modify` - to update an existing credential
    - `:delete` - to delete an existing credential
  * `:credential_data` - the data for the credential (required, binary)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:user_id, 0..0xFFFF}
          | {:credential_type, UserCredential.credential_type()}
          | {:credential_slot, 0..0xFFFF}
          | {:operation_type, UserCredential.credential_operation()}
          | {:credential_data, binary()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_id = Command.param!(command, :user_id)
    credential_type = Command.param!(command, :credential_type)
    credential_slot = Command.param!(command, :credential_slot)
    operation_type = Command.param!(command, :operation_type)
    credential_data = Command.param!(command, :credential_data)

    data = UserCredential.encode_credential_data(credential_type, credential_data)

    <<user_id::16, UserCredential.encode_credential_type(credential_type), credential_slot::16,
      UserCredential.encode_credential_operation(operation_type), byte_size(data)::8,
      data::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<user_id::16, credential_type, credential_slot::16, operation_type, length,
          credential_data::binary-size(length)>>
      ) do
    credential_type = UserCredential.decode_credential_type(credential_type)

    {:ok,
     [
       user_id: user_id,
       credential_type: credential_type,
       credential_slot: credential_slot,
       operation_type: UserCredential.decode_credential_operation(operation_type),
       credential_data: UserCredential.decode_credential_data(credential_type, credential_data)
     ]}
  end
end
