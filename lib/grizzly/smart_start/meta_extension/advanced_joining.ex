defmodule Grizzly.SmartStart.MetaExtension.AdvancedJoining do
  @moduledoc """
  This extension is used to advertise the Security keys to grant during S2
  bootstrapping to a SmartStart node in the provisioning list

  For more information about S2 security see the `Grizzly.Security` module
  """
  @behaviour Grizzly.SmartStart.MetaExtension

  import Bitwise

  alias Grizzly.Security

  @type t :: %__MODULE__{
          keys: nonempty_list(Security.key())
        }

  @enforce_keys [:keys]
  defstruct keys: nil

  @doc """
  Create a new `AdvancedJoining.t()`

  This will validate the keys passed in are valid S2 keys. If a key is not a
  valid S2 key this function will return `{:error, :invalid_keys}`.

  The `key` parameter cannot be an empty list. If an empty list is passed in
  then this function will return `{:error, :empty_keys}`
  """
  @spec new(nonempty_list(Security.key())) :: {:ok, t()} | {:error, :invalid_keys | :empty_keys}
  def new([]), do: {:error, :empty_keys}

  def new(keys) do
    if Enum.all?(keys, &key_valid?/1) do
      {:ok, %__MODULE__{keys: keys}}
    else
      {:error, :invalid_keys}
    end
  end

  @doc """
  Create a binary string from an `AdvancedJoining.t()`
  """
  @impl Grizzly.SmartStart.MetaExtension
  @spec from_binary(binary()) :: {:ok, t()} | {:error, :invalid_binary | :critical_bit_not_set}
  def from_binary(<<0x35::size(7), 0x01::size(1), 0x01, keys>>) do
    {:ok, %__MODULE__{keys: unmask_keys(keys)}}
  end

  def from_binary(<<0x35::size(7), 0x00::size(1), _rest::binary>>) do
    {:error, :critical_bit_not_set}
  end

  def from_binary(_), do: {:error, :invalid_binary}

  @doc """
  Create an `AdvancedJoining.t()` from a binary string

  If the binary string does not have the critical bit set then this function
  will return `{:error, :critical_bit_not_set}`
  """
  @impl Grizzly.SmartStart.MetaExtension
  @spec to_binary(t()) :: {:ok, binary()}
  def to_binary(%__MODULE__{keys: keys}) do
    keys_byte =
      Enum.reduce(keys, 0, fn
        :s2_unauthenticated, byte -> byte ||| 0x01
        :s2_authenticated, byte -> byte ||| 0x02
        :s2_access_control, byte -> byte ||| 0x04
        :s0, byte -> byte ||| 0x40
      end)

    {:ok, <<0x35::size(7), 0x01::size(1), 0x01, keys_byte>>}
  end

  defp unmask_keys(byte) do
    Enum.reduce(Security.keys(), [], fn key, keys ->
      if byte_has_key?(<<byte>>, key) do
        [key | keys]
      else
        keys
      end
    end)
  end

  defp byte_has_key?(<<_::size(7), 1::size(1)>>, :s2_unauthenticated), do: true
  defp byte_has_key?(<<_::size(6), 1::size(1), _::size(1)>>, :s2_authenticated), do: true
  defp byte_has_key?(<<_::size(5), 1::size(1), _::size(2)>>, :s2_access_control), do: true
  defp byte_has_key?(<<_::size(1), 1::size(1), _::size(6)>>, :s0), do: true
  defp byte_has_key?(_byte, _key), do: false

  defp key_valid?(key) do
    key in Security.keys()
  end
end
