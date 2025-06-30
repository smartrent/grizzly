defmodule Grizzly.ZWave.CommandClasses.UserCredential do
  @moduledoc """
  User Credential command class
  """

  alias Grizzly.ZWave.Encoding

  @behaviour Grizzly.ZWave.CommandClass

  @type user_type ::
          :general | :programming | :non_access | :duress | :disposable | :expiring | :remote_only

  @type user_operation :: :add | :modify | :delete

  @type credential_rule :: :single | :dual | :triple

  @type credential_type ::
          :none
          | :pin_code
          | :password
          | :rfid
          | :ble
          | :nfc
          | :uwb
          | :eye_biometric
          | :face_biometric
          | :finger_biometric
          | :hand_biometric
          | :unspecified_biometric

  @type credential_operation :: :add | :modify | :delete

  @type credential_capabilities :: %{
          learn_supported?: boolean(),
          supported_slots: pos_integer(),
          min_length: pos_integer(),
          max_length: pos_integer(),
          recommended_learn_timeout: non_neg_integer(),
          learn_steps: non_neg_integer(),
          hash_max_length: non_neg_integer()
        }

  @type credential_learn_operation :: :add | :modify

  @type modifier_type :: :dne | :unknown | :zwave | :local | :other

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x83

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :user_credential

  @doc "Encodes a credential rule to a byte value"
  @spec encode_credential_rule(credential_rule()) :: byte()
  def encode_credential_rule(:single), do: 1
  def encode_credential_rule(:dual), do: 2
  def encode_credential_rule(:triple), do: 3

  @doc "Decodes a credential rule from a byte value"
  @spec decode_credential_rule(byte()) :: credential_rule() | :unknown
  def decode_credential_rule(1), do: :single
  def decode_credential_rule(2), do: :dual
  def decode_credential_rule(3), do: :triple
  def decode_credential_rule(_), do: :unknown

  @doc "Encodes a user type to a byte value"
  @spec encode_user_type(user_type()) :: byte()
  def encode_user_type(:general), do: 0x00
  def encode_user_type(:programming), do: 0x03
  def encode_user_type(:non_access), do: 0x04
  def encode_user_type(:duress), do: 0x05
  def encode_user_type(:disposable), do: 0x06
  def encode_user_type(:expiring), do: 0x07
  def encode_user_type(:remote_only), do: 0x09

  @doc "Decodes a user type from a byte value"
  @spec decode_user_type(byte()) :: user_type() | :unknown
  def decode_user_type(0x00), do: :general
  def decode_user_type(0x03), do: :programming
  def decode_user_type(0x04), do: :non_access
  def decode_user_type(0x05), do: :duress
  def decode_user_type(0x06), do: :disposable
  def decode_user_type(0x07), do: :expiring
  def decode_user_type(0x09), do: :remote_only
  def decode_user_type(_), do: :unknown

  @doc "Encodes a user operation to a byte value"
  @spec encode_user_operation(user_operation()) :: byte()
  def encode_user_operation(:add), do: 0x00
  def encode_user_operation(:modify), do: 0x01
  def encode_user_operation(:delete), do: 0x02

  @doc "Decodes a user operation from a byte value"
  @spec decode_user_operation(byte()) :: user_operation() | :unknown
  def decode_user_operation(0x00), do: :add
  def decode_user_operation(0x01), do: :modify
  def decode_user_operation(0x02), do: :delete
  def decode_user_operation(_), do: :unknown

  @doc "Encodes a credential type to a byte value"
  @spec encode_credential_type(credential_type()) :: byte()
  def encode_credential_type(:none), do: 0x00
  def encode_credential_type(:pin_code), do: 0x01
  def encode_credential_type(:password), do: 0x02
  def encode_credential_type(:rfid), do: 0x03
  def encode_credential_type(:ble), do: 0x04
  def encode_credential_type(:nfc), do: 0x05
  def encode_credential_type(:uwb), do: 0x06
  def encode_credential_type(:eye_biometric), do: 0x07
  def encode_credential_type(:face_biometric), do: 0x08
  def encode_credential_type(:finger_biometric), do: 0x09
  def encode_credential_type(:hand_biometric), do: 0x0A
  def encode_credential_type(:unspecified_biometric), do: 0x0B

  @doc "Decodes a credential type from a byte value"
  @spec decode_credential_type(byte()) :: credential_type() | :unknown
  def decode_credential_type(0x00), do: :none
  def decode_credential_type(0x01), do: :pin_code
  def decode_credential_type(0x02), do: :password
  def decode_credential_type(0x03), do: :rfid
  def decode_credential_type(0x04), do: :ble
  def decode_credential_type(0x05), do: :nfc
  def decode_credential_type(0x06), do: :uwb
  def decode_credential_type(0x07), do: :eye_biometric
  def decode_credential_type(0x08), do: :face_biometric
  def decode_credential_type(0x09), do: :finger_biometric
  def decode_credential_type(0x0A), do: :hand_biometric
  def decode_credential_type(0x0B), do: :unspecified_biometric
  def decode_credential_type(_), do: :unknown

  @doc "Encodes credential operation to a byte value"
  @spec encode_credential_operation(credential_operation()) :: byte()
  def encode_credential_operation(:add), do: 0x00
  def encode_credential_operation(:modify), do: 0x01
  def encode_credential_operation(:delete), do: 0x02

  @doc "Decodes credential operation from a byte value"
  @spec decode_credential_operation(byte()) :: credential_operation() | :unknown
  def decode_credential_operation(0x00), do: :add
  def decode_credential_operation(0x01), do: :modify
  def decode_credential_operation(0x02), do: :delete
  def decode_credential_operation(_), do: :unknown

  @doc "Encodes modifier type to a byte value"
  @spec encode_modifier_type(modifier_type()) :: byte()
  def encode_modifier_type(:dne), do: 0x00
  def encode_modifier_type(:unknown), do: 0x01
  def encode_modifier_type(:zwave), do: 0x02
  def encode_modifier_type(:local), do: 0x03
  def encode_modifier_type(:other), do: 0x04

  @doc "Decodes modifier type from a byte value"
  @spec decode_modifier_type(byte()) :: modifier_type() | :unknown
  def decode_modifier_type(0x00), do: :dne
  def decode_modifier_type(0x01), do: :unknown
  def decode_modifier_type(0x02), do: :zwave
  def decode_modifier_type(0x03), do: :local
  def decode_modifier_type(0x04), do: :other
  def decode_modifier_type(_), do: :unknown

  @doc """
  Encodes credential data to a binary based on its type.

  Passwords are encoded as UTF-16 strings, while other types are left as-is.
  """
  @spec encode_credential_data(credential_type(), binary()) :: binary()
  def encode_credential_data(:password, data), do: Encoding.encode_string(data, :utf16)
  def encode_credential_data(_, data), do: data

  @doc """
  Decodes credential data from a binary based on its type.
  """
  @spec decode_credential_data(credential_type(), binary()) :: binary()
  def decode_credential_data(:password, data), do: Encoding.decode_string(data, :utf16)
  def decode_credential_data(_, data), do: data

  @doc "Encodes the credential learn operation to a byte value."
  @spec encode_credential_learn_operation(credential_learn_operation()) :: byte()
  def encode_credential_learn_operation(:add), do: 0x00
  def encode_credential_learn_operation(:modify), do: 0x01

  @doc "Decodes a credential learn operation from a byte value."
  @spec decode_credential_learn_operation(byte()) :: credential_learn_operation() | :unknown
  def decode_credential_learn_operation(0x00), do: :add
  def decode_credential_learn_operation(0x01), do: :modify
  def decode_credential_learn_operation(_), do: :unknown
end
