defmodule Grizzly.ZWave.Commands.CredentialLearnStart do
  @moduledoc """
  CredentialLearnStart is used to initiate the learning process for a credential.

  ## Parameters

  * `:user_id` - the ID of the user to learn the credential for (required)
  * `:credential_type` - the type of credential to learn (required)
  * `:credential_slot` - the slot for the credential to learn (required)
  * `:operation_type` - the type of operation for learning (required)
    - `:add` - to add a new credential
    - `:modify` - to update an existing credential
  * `:learn_timeout` - the timeout for the learning process in seconds (required, 0-255)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential

  @type param ::
          {:user_id, 1..0xFFFF}
          | {:credential_type, UserCredential.credential_type()}
          | {:credential_slot, 0..0xFFFF}
          | {:operation_type, UserCredential.credential_learn_operation()}
          | {:learn_timeout, byte()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    user_id = Command.param!(command, :user_id)
    credential_type = Command.param!(command, :credential_type)
    credential_slot = Command.param!(command, :credential_slot)
    operation_type = Command.param!(command, :operation_type)
    learn_timeout = Command.param!(command, :learn_timeout)

    <<user_id::16, UserCredential.encode_credential_type(credential_type), credential_slot::16,
      UserCredential.encode_credential_learn_operation(operation_type), learn_timeout>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<user_id::16, credential_type, credential_slot::16, _::6, operation_type::2,
          learn_timeout>>
      ) do
    {:ok,
     [
       user_id: user_id,
       credential_type: UserCredential.decode_credential_type(credential_type),
       credential_slot: credential_slot,
       operation_type: UserCredential.decode_credential_learn_operation(operation_type),
       learn_timeout: learn_timeout
     ]}
  end
end
