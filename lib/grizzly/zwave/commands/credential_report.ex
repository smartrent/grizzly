defmodule Grizzly.ZWave.Commands.CredentialReport do
  @moduledoc """
  CredentialReport is used to report the status of a credential at the sending node.

  ## Parameters

  * `:report_type` - the type of report (required)
  * `:user_id` - the ID of the user for the credential (required)
  * `:credential_type` - the type of credential (required)
  * `:credential_slot` - the slot of the credential (required)
  * `:read_back_supported?` - whether read back is supported (required)
  * `:credential_data` - the data for the credential (required). If `read_back_supported?`
    is `false`, this will be a hash of the credential data.
  * `:modifier_type` - the type of modifier (required)
  * `:modifier_node_id` - the node ID of the modifier (required). If modifier_type is :zwave,
    this will be the node ID of the Z-Wave node that modified the credential. For other modifier
    types, this value is manufacturer specific.
  * `:next_credential_type` - the type of the next credential (required)
  * `:next_credential_slot` - the slot of the next credential (required)
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

  @type report_type ::
          :added
          | :modified
          | :deleted
          | :unchanged
          | :response_to_get
          | :rejected_location_occupied
          | :rejected_location_empty
          | :duplicate
          | :manufacturer_security_rules
          | :wrong_user_id
          | :duplicate_admin_pin_code

  @type param ::
          {:report_type, report_type()}
          | {:user_id, 0..0xFFFF}
          | {:credential_type, UserCredential.credential_type()}
          | {:credential_slot, 0..0xFFFF}
          | {:read_back_supported?, boolean()}
          | {:credential_data, binary()}
          | {:modifier_type, UserCredential.modifier_type()}
          | {:modifier_node_id, 0..0xFFFF}
          | {:next_credential_type, UserCredential.credential_type()}
          | {:next_credential_slot, 0..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    report_type = Command.param!(command, :report_type)
    user_id = Command.param!(command, :user_id)
    credential_type = Command.param!(command, :credential_type)
    credential_slot = Command.param!(command, :credential_slot)
    read_back_supported? = Command.param!(command, :read_back_supported?)
    credential_data = Command.param!(command, :credential_data)
    modifier_type = Command.param!(command, :modifier_type)
    modifier_node_id = Command.param!(command, :modifier_node_id)
    next_credential_type = Command.param!(command, :next_credential_type)
    next_credential_slot = Command.param!(command, :next_credential_slot)

    credential_data = UserCredential.encode_credential_data(credential_type, credential_data)

    <<
      encode_report_type(report_type),
      user_id::16,
      UserCredential.encode_credential_type(credential_type),
      credential_slot::16,
      bool_to_bit(read_back_supported?)::1,
      0::7,
      byte_size(credential_data),
      credential_data::binary,
      UserCredential.encode_modifier_type(modifier_type),
      modifier_node_id::16,
      UserCredential.encode_credential_type(next_credential_type),
      next_credential_slot::16
    >>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<
        report_type,
        user_id::16,
        credential_type,
        credential_slot::16,
        read_back_supported?::1,
        _::7,
        credential_data_length::8,
        credential_data::binary-size(credential_data_length),
        modifier_type,
        modifier_node_id::16,
        next_credential_type,
        next_credential_slot::16
      >>) do
    credential_type = UserCredential.decode_credential_type(credential_type)

    {:ok,
     [
       report_type: decode_report_type(report_type),
       user_id: user_id,
       credential_type: credential_type,
       credential_slot: credential_slot,
       read_back_supported?: bit_to_bool(read_back_supported?),
       credential_data: UserCredential.decode_credential_data(credential_type, credential_data),
       modifier_type: UserCredential.decode_modifier_type(modifier_type),
       modifier_node_id: modifier_node_id,
       next_credential_type: UserCredential.decode_credential_type(next_credential_type),
       next_credential_slot: next_credential_slot
     ]}
  end

  defp encode_report_type(:added), do: 0x00
  defp encode_report_type(:modified), do: 0x01
  defp encode_report_type(:deleted), do: 0x02
  defp encode_report_type(:unchanged), do: 0x03
  defp encode_report_type(:response_to_get), do: 0x04
  defp encode_report_type(:rejected_location_occupied), do: 0x05
  defp encode_report_type(:rejected_location_empty), do: 0x06
  defp encode_report_type(:duplicate), do: 0x07
  defp encode_report_type(:manufacturer_security_rules), do: 0x08
  defp encode_report_type(:wrong_user_id), do: 0x09
  defp encode_report_type(:duplicate_admin_pin_code), do: 0x0A

  defp decode_report_type(0x00), do: :added
  defp decode_report_type(0x01), do: :modified
  defp decode_report_type(0x02), do: :deleted
  defp decode_report_type(0x03), do: :unchanged
  defp decode_report_type(0x04), do: :response_to_get
  defp decode_report_type(0x05), do: :rejected_location_occupied
  defp decode_report_type(0x06), do: :rejected_location_empty
  defp decode_report_type(0x07), do: :duplicate
  defp decode_report_type(0x08), do: :manufacturer_security_rules
  defp decode_report_type(0x09), do: :wrong_user_id
  defp decode_report_type(0x0A), do: :duplicate_admin_pin_code
  defp decode_report_type(_), do: :unknown
end
