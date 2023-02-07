defmodule Grizzly.ZWave.Encoding do
  @moduledoc """
  Utility functions for encoding/decoding common data types.
  """

  import Bitwise

  @type bit :: 0 | 1

  @type bitmask_index_to_value_fun(v) :: (index :: non_neg_integer() -> v | nil)
  @type bitmask_index_to_value_fun() :: bitmask_index_to_value_fun(term())

  @type bitmask_value_to_index_fun(v) :: (v -> non_neg_integer())
  @type bitmask_value_to_index_fun() :: bitmask_value_to_index_fun(term())

  @doc """
  Encodes an indexed bitmask.

  ### Examples

      iex> encode_indexed_bitmask([])
      <<>>

      iex> encode_indexed_bitmask(
      ...>   [{0, true}, {4, true}, {5, true}, {6, false}, {7, true}, {8, true}]
      ...> )
      <<0b10110001::8, 0b00000001::8>>

      iex> encode_indexed_bitmask(
      ...>   [{0, true}, {4, true}, {5, true}, {6, false}, {7, true}, {8, true}, {31, true}]
      ...> )
      <<0b10110001, 0b00000001, 0b00000000, 0b10000000>>
  """
  @spec encode_indexed_bitmask([{value_type, boolean()}], bitmask_value_to_index_fun(value_type)) ::
          binary()
        when value_type: var
  def encode_indexed_bitmask(values, index_fun \\ &Function.identity/1, opts \\ [])

  def encode_indexed_bitmask([], _, _), do: <<>>

  def encode_indexed_bitmask(values, index_fun, opts) do
    trim_empty_bytes? = Keyword.get(opts, :trim_empty_bytes?, true)
    values = Enum.map(values, fn {index, enabled?} -> {index_fun.(index), enabled?} end)

    values =
      if trim_empty_bytes? do
        Enum.filter(values, &elem(&1, 1))
      else
        values
      end

    max_index = Enum.max(values, fn {a, _}, {b, _} -> a >= b end) |> elem(0)
    num_bytes = ceil((max_index + 1) / 8)

    bitmasks = for _ <- 1..num_bytes, into: [], do: 0

    for byte_index <- 0..(num_bytes - 1), bit_index <- 0..7, reduce: bitmasks do
      acc ->
        index = byte_index * 8 + bit_index

        enabled? =
          Enum.find_value(values, false, fn
            {^index, v} -> v
            _ -> nil
          end)

        if enabled? do
          List.replace_at(acc, byte_index, bor(Enum.at(acc, byte_index, 0), bsl(1, bit_index)))
        else
          acc
        end
    end
    |> :binary.list_to_bin()
  end

  @doc """
  Decodes an indexed bitmask.

  ### Examples

      iex> decode_indexed_bitmask(<<>>)
      []

      iex> decode_indexed_bitmask(<<0b10110001::8>>)
      [{0, true}, {1, false}, {2, false}, {3, false}, {4, true}, {5, true}, {6, false}, {7, true}]
  """
  @spec decode_indexed_bitmask(binary(), bitmask_index_to_value_fun(value_type)) :: [
          {value_type, boolean()}
        ]
        when value_type: var
  def decode_indexed_bitmask(bitmask, value_fun \\ &Function.identity/1) do
    for {byte, byte_index} <- Enum.with_index(:binary.bin_to_list(bitmask)),
        bit_index <- 0..7,
        reduce: [] do
      acc ->
        index = byte_index * 8 + bit_index
        enabled? = band(byte, bsl(1, bit_index)) != 0

        case value_fun.(index) do
          nil -> acc
          value -> [{value, enabled?} | acc]
        end
    end
    |> Enum.sort()
  end

  @doc """
  Converts a bit into a boolean.

  ## Examples

      iex> bit_to_bool(1)
      true
      iex> bit_to_bool(0)
      false
  """
  @spec bit_to_bool(0 | 1) :: boolean()
  def bit_to_bool(bit), do: bit == 1

  @doc """
  Converts a boolean into a bit.

  ## Examples

      iex> bool_to_bit(true)
      1
      iex> bool_to_bit(false)
      0
  """
  @spec bool_to_bit(boolean()) :: 0 | 1
  def bool_to_bit(true), do: 1
  def bool_to_bit(false), do: 0

  @doc """
  Encodes an IPv6 address tuple into a 128-bit binary.

  ## Examples

      iex> encode_ipv6_address({0xfd00, 0xaaaa, 0, 0, 0, 0, 0, 2})
      <<0xfd00::16, 0xaaaa::16, 0::16, 0::16, 0::16, 0::16, 0::16, 2::16>>
  """
  @spec encode_ipv6_address(:inet.ip6_address()) :: binary()
  def encode_ipv6_address(ipv6_address) do
    for hextet <- Tuple.to_list(ipv6_address), into: <<>>, do: <<hextet::16>>
  end

  @doc """
  Decodes a 128-bit binary into an IPv6 address tuple.

  ## Examples

      iex> decode_ipv6_address(<<0xfd00::16, 0xaaaa::16, 0::16, 0::16, 0::16, 0::16, 0::16, 2::16>>)
      {0xfd00, 0xaaaa, 0, 0, 0, 0, 0, 2}
  """
  @spec decode_ipv6_address(binary()) :: :inet.ip6_address()
  def decode_ipv6_address(binary) do
    addr_list = for <<hextet::16 <- binary>>, into: [], do: hextet
    List.to_tuple(addr_list)
  end
end
