defmodule Grizzly.ZWave.Commands.UserReport do
  @moduledoc """
  UserReport is used to report the status of a user ID at the sending node.

  ## Parameters

  * `:report_type` - the type of report (required)
  * `:next_user_id` - the ID of the next user (required)
  * `:modifier_type` - the type of modifier (optional)
  * `:modifier_node_id` - the ID of the modifier node (optional)
  * `:user_id` - the ID of the user (required)
  * `:user_type` - the type of user (required)
  * `:user_active?` - whether the user is active (required)
  * `:credential_rule` - the credential rule (required)
  * `:expiring_timeout_minutes` - the expiring timeout in minutes (optional)
  * `:username_encoding` - the encoding of the username (optional)
  * `:username` - the username (optional)
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.Encoding

  @type report_type ::
          :added
          | :modified
          | :deleted
          | :unchanged
          | :response_to_get
          | :rejected_location_occupied
          | :rejected_location_empty
          | :zero_expiring_minutes_invalid

  @type param ::
          {:report_type, report_type()}
          | {:next_user_id, 0..0xFFFF}
          | {:modifier_type, UserCredential.modifier_type()}
          | {:modifier_node_id, 0..0xFFFF}
          | {:user_id, 0..0xFFFF}
          | {:user_type, UserCredential.user_type()}
          | {:user_active?, boolean()}
          | {:credential_rule, UserCredential.credential_rule()}
          | {:expiring_timeout_minutes, 0..0xFFFF}
          | {:username_encoding, Encoding.string_encoding()}
          | {:username, binary()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_report,
      command_byte: 0x07,
      command_class: UserCredential,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    report_type = Command.param!(command, :report_type)
    next_user_id = Command.param!(command, :next_user_id)
    modifier_type = Command.param!(command, :modifier_type)
    modifier_node_id = Command.param(command, :modifier_node_id, 0)
    user_id = Command.param!(command, :user_id)
    user_type = Command.param!(command, :user_type)
    user_active? = Command.param!(command, :user_active?)
    credential_rule = Command.param!(command, :credential_rule)
    expiring_timeout_minutes = Command.param!(command, :expiring_timeout_minutes)
    username_encoding = Command.param(command, :username_encoding, :ascii)
    username = Command.param!(command, :username)
    encoded_username = encode_string(username, username_encoding)

    <<encode_report_type(report_type), next_user_id::16,
      UserCredential.encode_modifier_type(modifier_type), modifier_node_id::16, user_id::16,
      UserCredential.encode_user_type(user_type), 0::7, bool_to_bit(user_active?)::1,
      UserCredential.encode_credential_rule(credential_rule), expiring_timeout_minutes::16, 0::5,
      encode_string_encoding(username_encoding)::3, byte_size(encoded_username),
      encoded_username::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<
        report_type,
        next_user_id::16,
        modifier_type,
        modifier_node_id::16,
        user_id::16,
        user_type,
        _::7,
        user_active?::1,
        credential_rule,
        expiring_timeout_minutes::16,
        _::5,
        username_encoding::3,
        username_length::8,
        username::binary-size(username_length)
      >>) do
    username_encoding = decode_string_encoding(username_encoding)

    {:ok,
     [
       report_type: decode_report_type(report_type),
       next_user_id: next_user_id,
       modifier_type: UserCredential.decode_modifier_type(modifier_type),
       modifier_node_id: modifier_node_id,
       user_id: user_id,
       user_type: UserCredential.decode_user_type(user_type),
       user_active?: bit_to_bool(user_active?),
       credential_rule: UserCredential.decode_credential_rule(credential_rule),
       expiring_timeout_minutes: expiring_timeout_minutes,
       username_encoding: username_encoding,
       username: decode_string(username, username_encoding)
     ]}
  end

  @impl Grizzly.ZWave.Command
  def report_matches_get?(get, report) do
    get_user_id = Command.param!(get, :user_id)
    report_user_id = Command.param!(report, :user_id)
    report_report_type = Command.param!(report, :report_type)

    get_user_id == report_user_id and report_report_type == :response_to_get
  end

  defp encode_report_type(:added), do: 0x00
  defp encode_report_type(:modified), do: 0x01
  defp encode_report_type(:deleted), do: 0x02
  defp encode_report_type(:unchanged), do: 0x03
  defp encode_report_type(:response_to_get), do: 0x04
  defp encode_report_type(:rejected_location_occupied), do: 0x05
  defp encode_report_type(:rejected_location_empty), do: 0x06
  defp encode_report_type(:zero_expiring_minutes_invalid), do: 0x07

  defp decode_report_type(0x00), do: :added
  defp decode_report_type(0x01), do: :modified
  defp decode_report_type(0x02), do: :deleted
  defp decode_report_type(0x03), do: :unchanged
  defp decode_report_type(0x04), do: :response_to_get
  defp decode_report_type(0x05), do: :rejected_location_occupied
  defp decode_report_type(0x06), do: :rejected_location_empty
  defp decode_report_type(0x07), do: :zero_expiring_minutes_invalid
  defp decode_report_type(_), do: :unknown
end
