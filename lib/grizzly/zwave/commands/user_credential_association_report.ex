defmodule Grizzly.ZWave.Commands.UserCredentialAssociationReport do
  @moduledoc """
  UserCredentialAssociationReport is used to report the status of a user credential
  association change initiated by a UserCredentialAssociationSet command.

  ## Parameters

  * `:credential_type` - the type of credential (required)
  * `:credential_slot` - the slot of the credential (required)
  * `:destination_user_id` - the ID of the user to which the credential is associated (required)
  * `:status` - the status of the association (required)
    - `:success` - association was successful
    - `:credential_type_invalid` - the credential type is invalid
    - `:credential_slot_invalid` - the credential slot is invalid
    - `:credential_slot_empty` - the credential slot is empty
    - `:destination_user_id_invalid` - the destination user ID is invalid
    - `:destination_user_id_nonexistent` - the destination user ID does not exist
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential

  @type status ::
          :success
          | :credential_type_invalid
          | :credential_slot_invalid
          | :credential_slot_empty
          | :destination_user_id_invalid
          | :destination_user_id_nonexistent

  @type param ::
          {:credential_type, UserCredential.credential_type()}
          | {:credential_slot, 1..0xFFFF}
          | {:destination_user_id, 1..0xFFFF}
          | {:status, status()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    credential_type = Command.param!(command, :credential_type)
    credential_slot = Command.param!(command, :credential_slot)
    destination_user_id = Command.param!(command, :destination_user_id)
    status = Command.param!(command, :status)

    <<UserCredential.encode_credential_type(credential_type), credential_slot::16,
      destination_user_id::16, encode_status(status)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<credential_type::8, credential_slot::16, destination_user_id::16, status::8>>
      ) do
    {:ok,
     [
       credential_type: UserCredential.decode_credential_type(credential_type),
       credential_slot: credential_slot,
       destination_user_id: destination_user_id,
       status: decode_status(status)
     ]}
  end

  defp encode_status(:success), do: 0x00
  defp encode_status(:credential_type_invalid), do: 0x01
  defp encode_status(:credential_slot_invalid), do: 0x02
  defp encode_status(:credential_slot_empty), do: 0x03
  defp encode_status(:destination_user_id_invalid), do: 0x04
  defp encode_status(:destination_user_id_nonexistent), do: 0x05

  defp decode_status(0x00), do: :success
  defp decode_status(0x01), do: :credential_type_invalid
  defp decode_status(0x02), do: :credential_slot_invalid
  defp decode_status(0x03), do: :credential_slot_empty
  defp decode_status(0x04), do: :destination_user_id_invalid
  defp decode_status(0x05), do: :destination_user_id_nonexistent
  defp decode_status(_), do: :unknown
end
