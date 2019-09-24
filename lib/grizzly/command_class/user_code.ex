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

  @spec encode_status(slot_status) :: {:ok, 0x01 | 0x00} | {:error, :invalid_arg, any()}
  def encode_status(:occupied), do: {:ok, 0x01}
  def encode_status(:available), do: {:ok, 0x00}
  def encode_status(other), do: {:error, :invalid_arg, other}

  @spec decode_slot_status(0x01 | 0x00) :: slot_status
  def decode_slot_status(0x01), do: :occupied
  def decode_slot_status(0x00), do: :available

  @spec encode_user_code(user_code) :: {:ok, [0x30..0x39]} | {:error, :invalid_arg, any()}
  def encode_user_code(user_code) do
    if Enum.all?(user_code, &(&1 in 0..9)) do
      encoded =
        user_code
        |> Enum.map(&digit_to_acsii/1)

      {:ok, encoded}
    else
      {:error, :invalid_arg, user_code}
    end
  end

  defp digit_to_acsii(0), do: 0x30
  defp digit_to_acsii(n) when n in 1..9, do: 0x30 + n
end
