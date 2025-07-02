defmodule Grizzly.ZWave.Commands.CredentialGet do
  @moduledoc """
  CredentialGet is used to request a specific credential from the receiving node.

  ## Parameters

  * `:user_id` - the ID of the user to get the credential for (required)
  * `:credential_type` - the type of credential to get (required)
  * `:credential_slot` - the slot of the credential to get (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.UserCredential

  @type param ::
          {:user_id, 0..0xFFFF}
          | {:credential_type, UserCredential.credential_type()}
          | {:credential_slot, 0..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :credential_get,
      command_byte: 0x0B,
      command_class: UserCredential,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_id = Command.param!(command, :user_id)
    credential_type = Command.param!(command, :credential_type)
    credential_slot = Command.param!(command, :credential_slot)

    <<user_id::16, UserCredential.encode_credential_type(credential_type), credential_slot::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<user_id::16, credential_type::8, credential_slot::16>>) do
    {:ok,
     [
       {:user_id, user_id},
       {:credential_type, UserCredential.decode_credential_type(credential_type)},
       {:credential_slot, credential_slot}
     ]}
  end
end
