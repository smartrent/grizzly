defmodule Grizzly.Security do
  @moduledoc """
  Helpers for security
  """
  import Bitwise

  @type key :: :s2_unauthenticated | :s2_authenticated | :s2_access_control | :s0

  @type key_byte :: 0x01 | 0x02 | 0x04 | 0x80

  @typedoc """
  Possible key exchange failures

  - `:none` - Bootstrapping was successful
  - `:key` - No match between requested and granted keys
  - `:scheme` - no scheme is supported by the controller or joining node
  - `:decrypt` - joining node failed to decrypt the input pin from the value. Wrong input value/DSK from user
  - `:cancel` - user has canceled the S2 bootstrapping
  - `:auth` - the echo kex change frame does not match the earlier exchanged frame
  - `:get` - the joining node requested a key that was not granted by the controller at an earlier stage
  - `:verify` - the joining node cannot verify and decrypt the exchanged key
  - `:report` - the including node transmitted a frame containing a different key than what was currently being exchanged
  """
  @type key_exchange_fail_type ::
          :none | :key | :scheme | :curves | :decrypt | :cancel | :auth | :get | :verify | :report

  @spec byte_to_keys(byte) :: [key]
  def byte_to_keys(granted_keys_byte) do
    <<s0::size(1), _::size(4), ac::size(1), auth::size(1), unauth::size(1)>> =
      <<granted_keys_byte>>

    keys = [s0: s0, ac: ac, auth: auth, unauth: unauth]

    Enum.reduce(keys, [], fn
      {:s0, 1}, acc -> acc ++ [:s0]
      {:ac, 1}, acc -> acc ++ [:s2_access_control]
      {:auth, 1}, acc -> acc ++ [:s2_authenticated]
      {:unauth, 1}, acc -> acc ++ [:s2_unauthenticated]
      {_, 0}, acc -> acc
    end)
  end

  @spec keys_to_byte([key]) :: byte
  def keys_to_byte(keys) do
    Enum.reduce(keys, 0, fn key, byte -> byte ||| key_byte(key) end)
  end

  @doc """
  Validate the user input pin length, should be a 16 bit number
  """
  @spec validate_user_input_pin_length(non_neg_integer()) :: :valid | :invalid
  def validate_user_input_pin_length(n) when n >= 0 and n <= 65535, do: :valid
  def validate_user_input_pin_length(_), do: :invalid

  @doc """
  Decode a byte repersentation of the key exchanged failed type
  """
  @spec failed_type_from_byte(byte()) :: key_exchange_fail_type() | :unk
  def failed_type_from_byte(0x00), do: :none
  def failed_type_from_byte(0x01), do: :key
  def failed_type_from_byte(0x02), do: :scheme
  def failed_type_from_byte(0x03), do: :curves
  def failed_type_from_byte(0x05), do: :decrypt
  def failed_type_from_byte(0x06), do: :cancel
  def failed_type_from_byte(0x07), do: :auth
  def failed_type_from_byte(0x08), do: :get
  def failed_type_from_byte(0x09), do: :verify
  def failed_type_from_byte(0x0A), do: :report
  def failed_type_from_byte(_), do: :unk

  @doc """
  Get the byte repersentation of a key.

  The key `:none` is an invalid key to encode to,
  so this function does not support encoding to that
  key.
  """
  @spec key_byte(key) :: key_byte()
  def key_byte(:s0), do: 0x80
  def key_byte(:s2_access_control), do: 0x04
  def key_byte(:s2_authenticated), do: 0x02
  def key_byte(:s2_unauthenticated), do: 0x01

  @doc """
  Gets the highest security level key from a key list

  Since Z-Wave will work at the highest S2 security group
  available on a node, if multiple groups are in a list of keys
  it will assume that highest level is the security level of the node
  who provided this list.

  If the node S0 security Z-Wave will response with granted keys
  with the lone key being S0.
  """
  @spec get_highest_level([key]) :: key | :none
  def get_highest_level([]), do: :none
  def get_highest_level([:s0]), do: :s0

  def get_highest_level(keys) do
    Enum.reduce(keys, fn
      :s2_access_control, _ ->
        :s2_access_control

      :s2_authenticated, last_highest when last_highest != :s2_access_control ->
        :s2_authenticated

      :s2_unauthenticated, last_highest
      when last_highest not in [:s2_authenticated, :s2_access_control] ->
        :s2_unauthenticated

      :s2_unauthenticated, :s2_authenticated ->
        :s2_authenticated

      :s2_unauthenticated, :s2_access_control ->
        :s2_access_control

      _, last_highest ->
        last_highest
    end)
  end
end
