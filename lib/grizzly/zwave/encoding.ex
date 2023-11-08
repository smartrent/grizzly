defmodule Grizzly.ZWave.Encoding do
  @moduledoc """
  Utility functions for encoding/decoding common data types.
  """

  import Bitwise

  @type encode_bitmask_opts :: [min_bytes: non_neg_integer()]

  @doc """
  Encodes a list of bit indexes into a bitmask.

  ### Examples

      iex> encode_bitmask([])
      <<>>

      iex> encode_bitmask([0, 4, 5, 7, 8, 35])
      <<0b10110001, 0b00000001, 0, 0, 0b00001000>>

      iex> encode_bitmask([31, 8, 5, 0, 4, 7])
      <<0b10110001, 0b00000001, 0b00000000, 0b10000000>>

      iex> encode_bitmask([0, 4, 5, 7], min_bytes: 3)
      <<0b10110001, 0, 0>>
  """
  @spec encode_bitmask([non_neg_integer()], encode_bitmask_opts()) ::
          binary()
  def encode_bitmask(values, opts \\ [])

  def encode_bitmask([], _), do: <<>>

  def encode_bitmask(values, opts) do
    min_bytes = Keyword.get(opts, :min_bytes, 0)
    required_bytes = ceil((Enum.max(values) + 1) / 8)
    num_bytes = max(min_bytes, required_bytes)

    bitmasks = for _ <- 1..num_bytes, into: [], do: 0

    for byte_index <- 0..(num_bytes - 1),
        bit_index <- 0..7,
        index = byte_index * 8 + bit_index,
        Enum.member?(values, index),
        reduce: bitmasks do
      acc ->
        List.replace_at(acc, byte_index, bor(Enum.at(acc, byte_index, 0), bsl(1, bit_index)))
    end
    |> :binary.list_to_bin()
  end

  @doc """
  Decodes an indexed bitmask.

  ### Examples

      iex> decode_bitmask(<<>>)
      []

      iex> decode_bitmask(<<0b10110001, 0, 0>>)
      [0, 4, 5, 7]

      iex> decode_bitmask(<<0b10110001, 0b00000001, 0, 0, 0b00001000>>)
      [0, 4, 5, 7, 8, 35]
  """
  @spec decode_bitmask(binary()) :: [non_neg_integer()]
  def decode_bitmask(bitmask) do
    for {byte, byte_index} <- bitmask |> :erlang.binary_to_list() |> Enum.with_index(),
        bit_index <- 0..7,
        index = byte_index * 8 + bit_index,
        band(byte, bsl(1, bit_index)) != 0,
        do: index
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
  Converts a float into a binary representation of a Z-Wave float according to
  the typical format.

  * precision (3 bits)
  * scale (2 bits)
  * size (3 bits)
  * value (n bytes, where n = size)
  """
  @spec zwave_float_to_binary(number(), byte()) :: binary()
  def zwave_float_to_binary(value, scale) do
    {int_value, precision, bytes} = encode_zwave_float(value)
    <<precision::3, scale::2, bytes::3, int_value::signed-size(bytes * 8)>>
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
      {-75255, 2, 4}
      iex> encode_zwave_float(-75.255)
      {-75255, 3, 4}
  """
  @spec encode_zwave_float(value :: number()) ::
          {int_value :: integer(), precision :: non_neg_integer(), size :: integer()}
  def encode_zwave_float(value) do
    # Before we start, we need to make sure the integer part of the value will
    # fit in 32 bits. As long as that's true, we can safely convert any value
    # into a Z-Wave float by decreasing the precision until we get a value that
    # we can encode, even if that means dropping the fractional part entirely.
    integer_part = round(value)
    <<test::signed-32>> = <<integer_part::signed-32>>

    if test != integer_part do
      raise ArgumentError, "Value #{value} would overflow 32 bits"
    end

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
  # We only get 3 bits to represent the precision, so the maximum possible value
  # is 7. The quick and dirty way to determine the precision of an arbitrary
  # float is to convert it to a string and count the number of digits after the
  # decimal point.
  @spec __float_precision__(number()) :: non_neg_integer()
  def __float_precision__(v, max_precision \\ 7)

  def __float_precision__(v, _) when is_integer(v), do: 0

  def __float_precision__(v, max_precision) when is_float(v) do
    rounded = Float.round(v, max_precision)

    calculated_precision =
      case String.split("#{rounded}", ".") do
        [_] ->
          0

        [_, dec] ->
          String.replace_trailing(dec, "0", "") |> String.length()
      end

    # Test the integer value to see if it overflows 32 bits (if so, we need to
    # reduce the precision).
    candidate = round(v * :math.pow(10, calculated_precision))

    <<test::signed-32>> = <<candidate::signed-32>>

    cond do
      test == candidate -> calculated_precision
      # We should have already checked for overflow, so we _should_ never hit this branch
      max_precision == 0 -> raise ArgumentError, "Value #{v} would overflow 32 bits"
      true -> __float_precision__(v, max_precision - 1)
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
    bytes_needed = ceil(bits / 8)

    # Even if we only need 3 bytes, we have to use 4.
    cond do
      bytes_needed == 3 -> 4
      bytes_needed > 4 -> raise ArgumentError, "Value #{int_value} would overflow 32 bits"
      true -> bytes_needed
    end
  end
end
