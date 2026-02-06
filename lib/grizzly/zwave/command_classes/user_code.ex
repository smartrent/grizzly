defmodule Grizzly.ZWave.CommandClasses.UserCode do
  @moduledoc """
  Command Class for working with user codes
  """

  @type user_id_status ::
          :available
          | :occupied
          | :disabled
          | :messaging
          | :passage
          | :status_not_available
          | byte()

  @type extended_user_id :: 0x0000..0xFFFF
  @type extended_user_code :: %{
          required(:user_id) => extended_user_code(),
          required(:user_id_status) => user_id_status(),
          required(:user_code) => String.t()
        }

  @type keypad_mode :: :normal | :vacation | :privacy | :lockout

  @spec user_id_status_to_byte(user_id_status()) :: byte()
  def user_id_status_to_byte(:available), do: 0x00
  def user_id_status_to_byte(:occupied), do: 0x01
  def user_id_status_to_byte(:disabled), do: 0x02
  def user_id_status_to_byte(:messaging), do: 0x03
  def user_id_status_to_byte(:passage), do: 0x04
  def user_id_status_to_byte(:status_not_available), do: 0xFE
  def user_id_status_to_byte(v) when v in 0..255, do: v

  @spec user_id_status_from_byte(byte()) :: user_id_status()
  def user_id_status_from_byte(0x00), do: :available
  def user_id_status_from_byte(0x01), do: :occupied
  def user_id_status_from_byte(0x02), do: :disabled
  def user_id_status_from_byte(0x03), do: :messaging
  def user_id_status_from_byte(0x04), do: :passage
  def user_id_status_from_byte(0xFE), do: :status_not_available
  def user_id_status_from_byte(v), do: v

  @spec keypad_mode_from_byte(0x00 | 0x01 | 0x02 | 0x03) :: keypad_mode()
  def keypad_mode_from_byte(0x00), do: :normal
  def keypad_mode_from_byte(0x01), do: :vacation
  def keypad_mode_from_byte(0x02), do: :privacy
  def keypad_mode_from_byte(0x03), do: :lockout

  @spec keypad_mode_to_byte(keypad_mode()) :: 0 | 1 | 2 | 3
  def keypad_mode_to_byte(:normal), do: 0x00
  def keypad_mode_to_byte(:vacation), do: 0x01
  def keypad_mode_to_byte(:privacy), do: 0x02
  def keypad_mode_to_byte(:lockout), do: 0x03

  def encode_extended_user_code(user_code) do
    user_id = user_code[:user_id]
    user_id_status = user_code[:user_id_status]
    user_code = user_code[:user_code]

    <<user_id::16, user_id_status_to_byte(user_id_status), 0::4, byte_size(user_code)::4,
      user_code::binary>>
  end

  @spec decode_extended_user_codes(binary()) ::
          {user_codes :: [extended_user_code()], remainder :: binary()}
  def decode_extended_user_codes(user_codes_bin) do
    {codes, rest} = do_decode_extended_user_codes([], user_codes_bin)
    {Enum.reverse(codes), rest}
  end

  defp do_decode_extended_user_codes(
         codes,
         <<user_id::16, user_id_status::8, _reserved::4, code_length::4,
           user_code::binary-size(code_length), rest::binary>>
       ) do
    user_code = %{
      user_id: user_id,
      user_id_status: user_id_status_from_byte(user_id_status),
      user_code: user_code
    }

    do_decode_extended_user_codes([user_code | codes], rest)
  end

  defp do_decode_extended_user_codes(codes, <<_next_user_id::16>> = rest), do: {codes, rest}
  defp do_decode_extended_user_codes(codes, <<>>), do: {codes, <<>>}
end
