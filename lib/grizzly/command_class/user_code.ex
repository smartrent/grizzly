defmodule Grizzly.CommandClass.UserCode do
  @type slot_id :: pos_integer
  @type slot_status :: :occupied | :available
  @type user_code :: String.t()

  @doc """
  The default empty code to be sent.

  This function is useful to use when trying to set a user code
  slot from occupied to available
  """
  @spec empty_code :: [0, ...]
  def empty_code() do
    [0, 0, 0, 0, 0, 0, 0, 0]
  end

  @spec encode_status(slot_status, map) :: {:ok, 0x01 | 0x00} | {:error, :invalid_arg, any()}
  def encode_status(:occupied, %{slot_id: 0}), do: {:error, :invalid_arg, :occupied}
  def encode_status(:occupied, _), do: {:ok, 0x01}
  def encode_status(:available, _), do: {:ok, 0x00}
  def encode_status(other), do: {:error, :invalid_arg, other}

  @spec decode_slot_status(0x01 | 0x00) :: slot_status
  def decode_slot_status(0x01), do: :occupied
  def decode_slot_status(0x00), do: :available

  @spec encode_user_code(user_code, map) :: {:ok, [0x30..0x39]} | {:error, :invalid_arg, any()}
  def encode_user_code(_user_code, %{slot_id: 0}), do: {:ok, :erlang.list_to_binary(empty_code())}

  def encode_user_code(_user_code, %{slot_status: :available}),
    do: {:ok, :erlang.list_to_binary(empty_code())}

  def encode_user_code(user_code, _) do
    ascii_digits = :erlang.binary_to_list(user_code)

    if Enum.all?(ascii_digits, &(&1 in 0x30..0x39)) do
      {:ok, :erlang.list_to_binary(ascii_digits)}
    else
      {:error, :invalid_arg, user_code}
    end
  end
end
