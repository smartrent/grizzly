defmodule Grizzly.ZWave.Security do
  @moduledoc """
  Helpers for security
  """
  import Bitwise

  @type s2_key :: :s2_unauthenticated | :s2_authenticated | :s2_access_control
  @type key :: s2_key() | :s0

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
    <<s0::1, _::4, ac::1, auth::1, unauth::1>> =
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

  @doc """
  Get the list of available security keys
  """
  @spec keys() :: [key()]
  def keys() do
    [:s2_unauthenticated, :s2_authenticated, :s2_access_control, :s0]
  end

  @spec keys_to_byte([key]) :: byte
  def keys_to_byte(keys) do
    Enum.reduce(keys, 0, fn key, byte -> byte ||| key_to_byte(key) end)
  end

  @doc """
  Validate the user input pin length, should be a 16 bit number
  """
  @spec validate_user_input_pin_length(non_neg_integer()) :: :valid | :invalid
  def validate_user_input_pin_length(n) when n >= 0 and n <= 65535, do: :valid
  def validate_user_input_pin_length(_), do: :invalid

  @doc """
  Decode a byte representation of the key exchanged failed type
  """
  @spec failed_type_from_byte(byte()) :: key_exchange_fail_type()
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

  @spec failed_type_to_byte(key_exchange_fail_type()) :: byte()
  def failed_type_to_byte(:none), do: 0x00
  def failed_type_to_byte(:key), do: 0x01
  def failed_type_to_byte(:scheme), do: 0x02
  def failed_type_to_byte(:curves), do: 0x03
  def failed_type_to_byte(:decrypt), do: 0x05
  def failed_type_to_byte(:cancel), do: 0x06
  def failed_type_to_byte(:auth), do: 0x07
  def failed_type_to_byte(:get), do: 0x08
  def failed_type_to_byte(:verify), do: 0x09
  def failed_type_to_byte(:report), do: 0x0A

  @doc """
  Get the byte representation of a key.

  The key `:none` is an invalid key to encode to,
  so this function does not support encoding to that
  key.
  """
  @spec key_to_byte(key()) :: key_byte()
  def key_to_byte(:s0), do: 0x80
  def key_to_byte(:s2_access_control), do: 0x04
  def key_to_byte(:s2_authenticated), do: 0x02
  def key_to_byte(:s2_unauthenticated), do: 0x01

  @doc """
  Get the key represented by the given byte.
  """
  @spec key_from_byte(key_byte()) :: key()
  def key_from_byte(0x80), do: :s0
  def key_from_byte(0x04), do: :s2_access_control
  def key_from_byte(0x02), do: :s2_authenticated
  def key_from_byte(0x01), do: :s2_unauthenticated

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
