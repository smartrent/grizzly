defmodule Grizzly.ZWave.Commands.UserCodeCapabilitiesReport do
  @moduledoc """
  This command is used to advertise User Code capabilities.

  ## Params

  * `:admin_code_supported?` - Whether the lock supports admin code functionality.
  * `:admin_code_deactivation_supported?` - Whether the lock supports deactivating an admin code.
  * `:user_code_checksum_supported?` - Whether the lock supports user code checksum functionality.
  * `:multi_user_code_report_supported?` - Whether the lock supports reporting multiple user codes
    via the Extended User Code Report command.
  * `:multi_user_code_set_supported?` - Whether the lock supports setting multiple user codes via
    the Extended User Code Set command.
  * `:supported_user_id_statuses` - A list of supported user ID statuses.
  * `:supported_keypad_modes` - A list of supported keypad modes.
  * `:supported_keypad_keys` - A list of supported keypad keys.
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode
  alias Grizzly.ZWave.DecodeError

  @type ascii_char :: 0..127

  @type param ::
          {:admin_code_supported?, boolean()}
          | {:admin_code_deactivation_supported?, boolean()}
          | {:user_code_checksum_supported?, boolean()}
          | {:multi_user_code_report_supported?, boolean()}
          | {:multi_user_code_set_supported?, boolean()}
          | {:supported_user_id_statuses, [UserCode.user_id_status()]}
          | {:supported_keypad_modes, [UserCode.keypad_mode()]}
          | {:supported_keypad_keys, [ascii_char()]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_code_capabilities_report,
      command_byte: 0x07,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    mc = Command.param(command, :admin_code_supported?, false) |> bool_to_bit()
    mcd = Command.param(command, :admin_code_deactivation_supported?, false) |> bool_to_bit()
    ucc = Command.param(command, :user_code_checksum_supported?, false) |> bool_to_bit()
    mucr = Command.param(command, :multi_user_code_report_supported?, false) |> bool_to_bit()
    mucs = Command.param(command, :multi_user_code_set_supported?, false) |> bool_to_bit()

    supported_user_id_statuses =
      Command.param(command, :supported_user_id_statuses, [])
      |> Enum.map(&UserCode.user_id_status_to_byte/1)
      |> encode_bitmask()

    supported_keypad_modes =
      Command.param(command, :supported_keypad_modes, [])
      |> Enum.map(&UserCode.keypad_mode_to_byte/1)
      |> encode_bitmask()

    supported_keypad_keys =
      Command.param(command, :supported_keypad_keys, [])
      |> encode_bitmask()

    <<mc::1, mcd::1, 0::1, byte_size(supported_user_id_statuses)::5>> <>
      supported_user_id_statuses <>
      <<ucc::1, mucr::1, mucs::1, byte_size(supported_keypad_modes)::5>> <>
      supported_keypad_modes <>
      <<0::3, byte_size(supported_keypad_keys)::5>> <>
      supported_keypad_keys
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<mc_support::1, mcd_support::1, _reserved::1, user_id_status_len::5,
          supported_user_id_statuses::binary-size(user_id_status_len), ucc_support::1,
          mucr_support::1, mucs_support::1, keypad_modes_len::5,
          supported_keypad_modes::binary-size(keypad_modes_len), _reserved2::3,
          supported_keypad_keys_len::5,
          supported_keypad_keys_bitmask::binary-size(supported_keypad_keys_len)>>
      ) do
    user_id_statuses =
      supported_user_id_statuses
      |> decode_bitmask()
      |> Enum.map(&UserCode.user_id_status_from_byte/1)
      |> Enum.reject(&(&1 == :unknown))

    keypad_modes =
      supported_keypad_modes
      |> decode_bitmask()
      |> Enum.map(&UserCode.keypad_mode_from_byte/1)
      |> Enum.reject(&(&1 == :unknown))

    {:ok,
     [
       admin_code_supported?: mc_support == 1,
       admin_code_deactivation_supported?: mcd_support == 1,
       user_code_checksum_supported?: ucc_support == 1,
       multi_user_code_report_supported?: mucr_support == 1,
       multi_user_code_set_supported?: mucs_support == 1,
       supported_user_id_statuses: user_id_statuses,
       supported_keypad_modes: keypad_modes,
       supported_keypad_keys: decode_bitmask(supported_keypad_keys_bitmask)
     ]}
  end
end
