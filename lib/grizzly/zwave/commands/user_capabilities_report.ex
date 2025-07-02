defmodule Grizzly.ZWave.Commands.UserCapabilitiesReport do
  @moduledoc """
  UserCapabilitiesReport

  ## Parameters

  * `:max_users`
  * `:supported_credential_rules`
  * `:username_max_length`
  * `:user_schedule_supported?`
  * `:all_users_checksum_supported?`
  * `:user_checksum_supported?`
  * `:supported_user_types`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.{Command, DecodeError, Encoding}
  alias Grizzly.ZWave.CommandClasses.UserCredential

  @type param ::
          {:max_users, 0..0xFFFF}
          | {:supported_credential_rules, [UserCredential.credential_rule()]}
          | {:username_max_length, byte()}
          | {:user_schedule_supported?, boolean()}
          | {:all_users_checksum_supported?, boolean()}
          | {:user_checksum_supported?, boolean()}
          | {:supported_username_encoding, [Encoding.string_encoding()]}
          | {:supported_user_types, [UserCredential.user_type()]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_capabilities_report,
      command_byte: 0x02,
      command_class: UserCredential,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    max_users = Command.param!(command, :max_users)
    supported_credential_rules = Command.param!(command, :supported_credential_rules)
    username_max_length = Command.param!(command, :username_max_length)
    user_schedule_supported? = Command.param!(command, :user_schedule_supported?)
    all_users_checksum_supported? = Command.param!(command, :all_users_checksum_supported?)
    user_checksum_supported? = Command.param!(command, :user_checksum_supported?)
    supported_user_types = Command.param!(command, :supported_user_types)

    supported_username_encoding =
      Command.param(command, :supported_username_encoding, [:ascii, :extended_ascii, :utf16])

    utf16_supported? = :utf16 in supported_username_encoding
    extended_ascii_supported? = :extended_ascii in supported_username_encoding
    ascii_supported? = :ascii in supported_username_encoding

    supported_credential_rules =
      supported_credential_rules
      |> Enum.map(&UserCredential.encode_credential_rule/1)
      |> encode_bitmask()

    supported_user_types =
      supported_user_types
      |> Enum.map(&UserCredential.encode_user_type/1)
      |> encode_bitmask()

    <<max_users::16, supported_credential_rules::binary, username_max_length,
      bool_to_bit(user_schedule_supported?)::1, bool_to_bit(all_users_checksum_supported?)::1,
      bool_to_bit(user_checksum_supported?)::1, bool_to_bit(utf16_supported?)::1,
      bool_to_bit(extended_ascii_supported?)::1, bool_to_bit(ascii_supported?)::1, 0::2,
      byte_size(supported_user_types), supported_user_types::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<max_users::16, supported_credential_rules::1-bytes, username_max_length,
          user_schedule_supported?::1, all_users_checksum_supported?::1,
          user_checksum_supported?::1, utf16_supported?::1, extended_ascii_supported?::1,
          ascii_supported?::1, _reserved::2, supported_user_types_length,
          supported_user_types::binary-size(supported_user_types_length)>>
      ) do
    supported_credential_rules =
      supported_credential_rules
      |> decode_bitmask()
      |> Enum.map(&UserCredential.decode_credential_rule/1)
      |> Enum.reject(&(&1 == :unknown))

    supported_user_types =
      supported_user_types
      |> decode_bitmask()
      |> Enum.map(&UserCredential.decode_user_type/1)
      |> Enum.reject(&(&1 == :unknown))

    supported_username_encoding =
      [
        if(utf16_supported? == 1, do: :utf16, else: nil),
        if(extended_ascii_supported? == 1, do: :extended_ascii, else: nil),
        if(ascii_supported? == 1, do: :ascii, else: nil)
      ]
      |> Enum.reject(&is_nil/1)

    {:ok,
     [
       max_users: max_users,
       supported_credential_rules: supported_credential_rules,
       username_max_length: username_max_length,
       user_schedule_supported?: bit_to_bool(user_schedule_supported?),
       all_users_checksum_supported?: bit_to_bool(all_users_checksum_supported?),
       user_checksum_supported?: bit_to_bool(user_checksum_supported?),
       supported_username_encoding: supported_username_encoding,
       supported_user_types: supported_user_types
     ]}
  end
end
