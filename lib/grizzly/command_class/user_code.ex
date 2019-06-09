defmodule Grizzly.CommandClass.UserCode do
  @type slot_id :: pos_integer
  @type slot_status :: :occupied | :available
  @type user_code :: [0..9]

  @doc """
  The default empty code to be sent.

  This function is useful to use when trying to set a user code
  slot from occupied to available
  """
  @spec empty_code :: [0, ...]
  def empty_code() do
    [0, 0, 0, 0, 0, 0, 0, 0]
  end

  @spec status_to_hex(slot_status) :: 0x01 | 0x00
  def status_to_hex(:occupied), do: 0x01
  def status_to_hex(:available), do: 0x00

  @spec decode_slot_status(0x01 | 0x00) :: slot_status
  def decode_slot_status(0x01), do: :occupied
  def decode_slot_status(0x00), do: :available

  @spec encode_user_code(user_code) :: [0x30..0x39]
  def encode_user_code(user_code) do
    user_code
    |> Enum.map(&digit_to_acsii/1)
  end

  defp digit_to_acsii(0), do: 0x30
  defp digit_to_acsii(n) when n in 1..9, do: 0x30 + n
end
