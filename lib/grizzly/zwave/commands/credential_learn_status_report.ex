defmodule Grizzly.ZWave.Commands.CredentialLearnStatusReport do
  @moduledoc """
  CredentialLearnStatusReport is used to report the status of the learning process
  for a credential.

  ## Parameters

  * `:status` - the status of the learning process (required)
    - `:started` - learning has started
    - `:success` - learning was successful
    - `:already_in_progress` - learning is already in progress
    - `:ended_not_due_to_timeout` - learning ended but not due to timeout
    - `:timeout` - learning timed out
    - `:learn_step_retry` - retrying a learn step
    - `:invalid_add_operation` - invalid add operation
    - `:invalid_modify_operation` - invalid modify operation
  * `:user_id` - the ID of the user for the credential (required)
  * `:credential_type` - the type of credential (required)
  * `:credential_slot` - the slot of the credential (required)
  * `:steps_remaining` - the number of learn steps remaining (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

  @type learn_status ::
          :started
          | :success
          | :already_in_progress
          | :ended_not_due_to_timeout
          | :timeout
          | :learn_step_retry
          | :invalid_add_operation
          | :invalid_modify_operation

  @type param ::
          {:status, learn_status()}
          | {:user_id, 1..0xFFFF}
          | {:credential_type, UserCredential.credential_type()}
          | {:credential_slot, 1..0xFFFF}
          | {:steps_remaining, byte()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :credential_learn_status_report,
      command_byte: 0x11,
      command_class: UserCredential,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    status = Command.param!(command, :status)
    user_id = Command.param!(command, :user_id)
    credential_type = Command.param!(command, :credential_type)
    credential_slot = Command.param!(command, :credential_slot)
    steps_remaining = Command.param!(command, :steps_remaining)

    <<encode_status(status), user_id::16, UserCredential.encode_credential_type(credential_type),
      credential_slot::16, steps_remaining>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<status, user_id::16, credential_type, credential_slot::16, steps_remaining>>
      ) do
    {:ok,
     [
       status: decode_status(status),
       user_id: user_id,
       credential_type: UserCredential.decode_credential_type(credential_type),
       credential_slot: credential_slot,
       steps_remaining: steps_remaining
     ]}
  end

  defp encode_status(:started), do: 0x00
  defp encode_status(:success), do: 0x01
  defp encode_status(:already_in_progress), do: 0x02
  defp encode_status(:ended_not_due_to_timeout), do: 0x03
  defp encode_status(:timeout), do: 0x04
  defp encode_status(:learn_step_retry), do: 0x05
  defp encode_status(:invalid_add_operation), do: 0xFE
  defp encode_status(:invalid_modify_operation), do: 0xFF

  defp decode_status(0x00), do: :started
  defp decode_status(0x01), do: :success
  defp decode_status(0x02), do: :already_in_progress
  defp decode_status(0x03), do: :ended_not_due_to_timeout
  defp decode_status(0x04), do: :timeout
  defp decode_status(0x05), do: :learn_step_retry
  defp decode_status(0xFE), do: :invalid_add_operation
  defp decode_status(0xFF), do: :invalid_modify_operation
  defp decode_status(_), do: :unknown
end
