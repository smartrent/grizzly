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

  @doc """
  Converts a float into a tuple containing an integer representation of the float,
  the factor of 10 by which the integer must be divided to get the original float,
  and the number of bytes needed to represent the value as a signed integer.

  ## Examples

      iex> encode_zwave_float(0)
      {0, 0, 1}
      iex> encode_zwave_float(-1.5)
      {-15, 1, 1}
      iex> encode_zwave_float(-1.50)
      {-15, 1, 1}
      iex> encode_zwave_float(128)
      {128, 0, 2}
      iex> encode_zwave_float(127.5)
      {1275, 1, 2}
      iex> encode_zwave_float(-75.25)
      {-7525, 2, 2}
      iex> encode_zwave_float(-752.55)
      {-75255, 2, 3}
      iex> encode_zwave_float(-75.255)
      {-75255, 3, 3}
  """
  @spec encode_zwave_float(value :: number()) ::
          {int_value :: integer(), precision :: non_neg_integer(), size :: integer()}
  def encode_zwave_float(value) do
    # Convert the value to an integer by multiplying it by 10 ^ precision and
    # rounding the result to the nearest integer. If the value is already an
    # integer, leave it as-is.
    precision = __float_precision__(value)

    int_value =
      case value do
        v when is_integer(v) -> v
        v -> round(v * :math.pow(10, precision))
      end

    # Determine the number of bytes needed to represent the integer value.
    size = __float_bytes_needed__(int_value)

    {int_value, precision, size}
  end

  @doc """
  Converts an integer value and non-zero precision into a float by dividing the
  integer by `10 ^ precision`. If the given precision is zero, the integer is
  returned as-is.

  ## Examples

      iex> decode_zwave_float(0, 0)
      0
      iex> decode_zwave_float(0, 2)
      0.0
      iex> decode_zwave_float(1234, 2)
      12.34
      iex> decode_zwave_float(1234, 1)
      123.4
      iex> decode_zwave_float(1234, 0)
      1234
      iex> decode_zwave_float(-1234, 2)
      -12.34
  """
  @spec decode_zwave_float(integer(), non_neg_integer()) :: number()
  def decode_zwave_float(int_value, 0), do: int_value

  def decode_zwave_float(int_value, precision) do
    int_value / :math.pow(10, precision)
  end

  @doc false
  @spec __float_precision__(number()) :: non_neg_integer()
  def __float_precision__(v) when is_integer(v), do: 0

  # We only get 3 bits to represent the precision, so the maximum possible value
  # is 7. The quick and dirty way to determine the precision of an arbitrary
  # float is to convert it to a string and count the number of digits after the
  # decimal point.
  def __float_precision__(v) when is_float(v) do
    case String.split("#{v}", ".") do
      [_] -> 0
      [_, dec] -> String.length(dec)
    end
  end

  @doc false
  def __float_bits_needed__(0), do: 1

  def __float_bits_needed__(int_value) do
    # This is essentially the same as rounding int_value up to the next power of
    # 2 and then taking the log2. We add 1 to the result to account for the sign
    # bit.
    bits = ceil(:math.log2(abs(int_value))) + 1

    <<msb::1, _rest::size(bits - 1)>> = <<int_value::signed-size(bits)>>

    if msb == 1 && int_value > 0 do
      bits + 1
    else
      bits
    end
  end

  @doc false
  def __float_bytes_needed__(int_value) do
    bits = __float_bits_needed__(int_value)
    ceil(bits / 8)
  end
end
