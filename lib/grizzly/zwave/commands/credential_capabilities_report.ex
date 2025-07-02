defmodule Grizzly.ZWave.Commands.CredentialCapabilitiesReport do
  @moduledoc """
  CredentialCapabilitiesReport is used to report the capabilities related to credentials
  at the sending node.

  ## Parameters

  * `:credential_checksum_supported?` - indicates if credential checksum is supported (required)
  * `:admin_code_supported?` - indicates if admin code is supported (required)
  * `:admin_code_deactivation_supported?` - indicates if admin code deactivation is supported (required)
  * `:credential_types` - a map of supported credential types (required)
    * `:learn_supported?` - indicates if learning is supported (required)
    * `:supported_slots` - a list of supported slots (required)
    * `:min_length` - the minimum length of the credential (required)
    * `:max_length` - the maximum length of the credential (required)
    * `:recommended_learn_timeout` - recommended timeout for learning (required)
    * `:learn_steps` - a list of learn steps (required)
    * `:hash_max_length` - the maximum length of the hash for the credential (required)
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.UserCredential

  @type param ::
          {:credential_checksum_supported?, boolean()}
          | {:admin_code_supported?, boolean()}
          | {:admin_code_deactivation_supported?, boolean()}
          | {:credential_types,
             %{
               required(UserCredential.credential_type()) =>
                 UserCredential.credential_capabilities()
             }}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :credential_capabilities_report,
      command_byte: 0x04,
      command_class: UserCredential,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    credential_checksum_supported? = Command.param!(command, :credential_checksum_supported?)
    admin_code_supported? = Command.param!(command, :admin_code_supported?)

    admin_code_deactivation_supported? =
      Command.param!(command, :admin_code_deactivation_supported?)

    credential_types = Command.param!(command, :credential_types)

    encoded_credential_types =
      for {credential_type, capabilities} <- credential_types do
        [
          UserCredential.encode_credential_type(credential_type),
          <<bool_to_bit(capabilities.learn_supported?)::1, 0::7>>,
          <<capabilities.supported_slots::16>>,
          capabilities.min_length,
          capabilities.max_length,
          capabilities.recommended_learn_timeout,
          capabilities.learn_steps,
          capabilities.hash_max_length
        ]
      end
      |> Enum.zip_with(&Function.identity/1)
      |> IO.iodata_to_binary()

    <<
      bool_to_bit(credential_checksum_supported?)::1,
      bool_to_bit(admin_code_supported?)::1,
      bool_to_bit(admin_code_deactivation_supported?)::1,
      0::5,
      Enum.count(credential_types),
      encoded_credential_types::binary
    >>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<credential_checksum_supported?::1, admin_code_supported?::1,
          admin_code_deactivation_supported?::1, _reserved::5, num_credential_types,
          credential_type_bytes::binary-size(num_credential_types),
          credential_learn_supported_bytes::binary-size(num_credential_types),
          supported_slots::binary-size(num_credential_types * 2),
          min_credential_length_bytes::binary-size(num_credential_types),
          max_credential_length_bytes::binary-size(num_credential_types),
          credential_learn_recommended_timeout_bytes::binary-size(num_credential_types),
          credential_learn_step_count_bytes::binary-size(num_credential_types),
          max_credential_hash_length_bytes::binary-size(num_credential_types)>>
      ) do
    credential_types =
      credential_type_bytes
      |> :erlang.binary_to_list()
      |> Enum.map(&UserCredential.decode_credential_type/1)

    credential_learn_supported =
      for <<b::1, _reserved::7 <- credential_learn_supported_bytes>>, do: bit_to_bool(b)

    supported_slots = for <<slot::16 <- supported_slots>>, do: slot

    types =
      [
        credential_types,
        credential_learn_supported,
        supported_slots,
        :erlang.binary_to_list(min_credential_length_bytes),
        :erlang.binary_to_list(max_credential_length_bytes),
        :erlang.binary_to_list(credential_learn_recommended_timeout_bytes),
        :erlang.binary_to_list(credential_learn_step_count_bytes),
        :erlang.binary_to_list(max_credential_hash_length_bytes)
      ]
      |> Enum.zip_with(fn [
                            credential_type,
                            learn_supported?,
                            supported_slots,
                            min_length,
                            max_length,
                            recommended_learn_timeout,
                            learn_steps,
                            hash_max_length
                          ] ->
        {credential_type,
         %{
           learn_supported?: learn_supported?,
           supported_slots: supported_slots,
           min_length: min_length,
           max_length: max_length,
           recommended_learn_timeout: recommended_learn_timeout,
           learn_steps: learn_steps,
           hash_max_length: hash_max_length
         }}
      end)
      |> Map.new()

    {:ok,
     [
       credential_checksum_supported?: bit_to_bool(credential_checksum_supported?),
       admin_code_supported?: bit_to_bool(admin_code_supported?),
       admin_code_deactivation_supported?: bit_to_bool(admin_code_deactivation_supported?),
       credential_types: types
     ]}
  end
end
