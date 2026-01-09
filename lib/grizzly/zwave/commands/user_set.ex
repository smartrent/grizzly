defmodule Grizzly.ZWave.Commands.UserSet do
  @moduledoc """
  UserSet

  ## Parameters

  * `:operation_type` - the type of operation to perform on the user (required)
    - `:add` - add a new user
    - `:update` - update an existing user
    - `:delete` - delete an existing user
  * `:user_id` - the ID of the user to set (required)
  * `:user_type` - the type of user (required)
  * `:user_active?` - whether the user is active (required, boolean)
  * `:credential_rule` - the rule for evaluating this user's credentials (required)
  * `:expiring_timeout_minutes` - the timeout in minutes for expiring credentials (optional, defaults to 0)
  * `:username_encoding` - how to encode the username when sending via Z-Wave (defaults to `:ascii`)
  * `:username` - a UTF-8 string representing the username
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding

  @type param ::
          {:operation_type, UserCredential.user_operation()}
          | {:user_id, 1..0xFFFF}
          | {:user_type, UserCredential.user_type()}
          | {:user_active?, boolean()}
          | {:credential_rule, UserCredential.credential_rule()}
          | {:expiring_timeout_minutes, 0..0xFFFF}
          | {:username_encoding, Encoding.string_encoding()}
          | {:username, binary()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    operation_type = Command.param!(command, :operation_type)
    user_id = Command.param!(command, :user_id)
    user_type = Command.param!(command, :user_type)
    user_active? = Command.param!(command, :user_active?)
    credential_rule = Command.param!(command, :credential_rule)
    expiring_timeout_minutes = Command.param(command, :expiring_timeout_minutes, 0)
    username_encoding = Command.param(command, :username_encoding, :ascii)
    username = Command.param!(command, :username)
    encoded_username = encode_string(username, username_encoding)

    <<0::6, UserCredential.encode_user_operation(operation_type)::2, user_id::16,
      UserCredential.encode_user_type(user_type), 0::7, bool_to_bit(user_active?)::1,
      UserCredential.encode_credential_rule(credential_rule), expiring_timeout_minutes::16, 0::5,
      encode_string_encoding(username_encoding)::3, byte_size(encoded_username),
      encoded_username::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<_::6, operation_type::2, user_id::16, user_type, _::7, user_active?::1, credential_rule,
          expiring_timeout_minutes::16, _::5, username_encoding::3, username_length::8,
          username::binary-size(username_length)>>
      ) do
    username_encoding = decode_string_encoding(username_encoding)

    {:ok,
     [
       operation_type: UserCredential.decode_user_operation(operation_type),
       user_id: user_id,
       user_type: UserCredential.decode_user_type(user_type),
       user_active?: bit_to_bool(user_active?),
       credential_rule: UserCredential.decode_credential_rule(credential_rule),
       expiring_timeout_minutes: expiring_timeout_minutes,
       username_encoding: username_encoding,
       username: decode_string(username, username_encoding)
     ]}
  end
end
