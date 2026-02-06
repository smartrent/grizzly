defmodule Grizzly.ZWave.Encoding do
  @moduledoc """
  Utility functions for encoding/decoding common data types.
  """

  import Bitwise

  alias Grizzly.ZWave.ZWEnum

  @type encode_bitmask_opts :: [min_bytes: non_neg_integer()]

  @type string_encoding :: :ascii | :extended_ascii | :utf16

  @typedoc """
  Common representation for durations used in Z-Wave command classes.

  Durations of 0..127 seconds are encoded with 1-second resolution. Durations of
  128..7560 seconds are encoded with 1-minute resolution. Larger durations are
  not supported and will be encoded as unknown (0xFE).

  See section 2.1.7.3 of the Z-Wave Specification for details.
  """
  @type duration :: 0..7560 | :unknown | :default

  @max_duration 126 * 60

  @doc """
  Reduce over a binary by repeatedly applying a reducer function.

  The reducer function should take a binary and an accumulator and return either
  `{:cont, {new_acc, rest}}` to continue reducing with the new accumulator and
  remaining binary, or `{:halt, {new_acc, rest}}` to stop reducing and return the
  final accumulator and remaining binary.

  The reduction will halt automatically when the binary is empty.

  ## Examples

      iex> reducer = fn
      ...>   <<byte, rest::binary>>, acc when byte < 5 ->
      ...>     {:cont, {[byte | acc], rest}}
      ...>   binary, acc ->
      ...>     {:halt, {acc, binary}}
      ...> end
      iex> reduce_binary_while(<<1, 2, 3, 6, 4>>, [], reducer)
      {[3, 2, 1], <<6, 4>>}
      iex> reduce_binary_while(<<1, 2, 3>>, reducer)
      {[3, 2, 1], <<>>}
  """
  @spec reduce_binary_while(binary(), term(), (binary(), acc :: term() ->
                                                 {:halt | :cont,
                                                  {acc :: term(), rest :: binary()}})) ::
          {acc :: term(), rest :: binary()}
  def reduce_binary_while(binary, acc \\ [], reducer_fun)

  def reduce_binary_while(<<>>, acc, _), do: {acc, <<>>}

  def reduce_binary_while(binary, acc, reducer_fun) do
    case reducer_fun.(binary, acc) do
      {:cont, {^acc, ^binary}} ->
        raise RuntimeError,
              "Reducer function must consume some of the binary or modify its accumulator"

      {:cont, {new_acc, rest}} ->
        reduce_binary_while(rest, new_acc, reducer_fun)

      {:halt, {new_acc, rest}} ->
        {new_acc, rest}
    end
  end

  @doc """
  Reduce over a binary by repeatedly applying a reducer function until the binary
  is empty.

  The reducer function should take a binary and an accumulator and return a tuple
  `{new_acc, rest}` where `new_acc` is the updated accumulator and `rest` is the
  remaining binary to process.

  ## Examples

      iex> reducer = fn
      ...>   <<word::16, rest::binary>>, acc ->
      ...>     {[word | acc], rest}
      ...>   <<byte, rest::binary>>, acc ->
      ...>     {[byte | acc], rest}
      ...> end
      iex> reduce_binary(<<1, 2, 3>>, [], reducer)
      [3, 258]
  """
  @spec reduce_binary(binary(), term(), (binary(), acc :: term() ->
                                           {acc :: term(), rest :: binary()})) :: acc :: term()
  def reduce_binary(binary, acc \\ [], reducer_fun) do
    reduce_binary_while(binary, acc, fn binary, acc ->
      {:cont, reducer_fun.(binary, acc)}
    end)
    |> elem(0)
  end

  @doc """
  Encodes a UTF-8 string using the specified encoding type.

  ASCII and extended ASCII encodings remove non-ASCII characters, while
  UTF-16 encoding converts the string to a UTF-16 binary representation.
  """
  @spec encode_string(binary(), string_encoding()) :: binary()
  def encode_string(str, :ascii), do: String.replace(str, ~r/[^\x00-\x7F]/, "")
  def encode_string(str, :extended_ascii), do: String.replace(str, ~r/[^\x00-\xFF]/, "")
  def encode_string(str, :utf16), do: convert_str(str, :utf8, :utf16)

  @doc """
  Decodes a binary string into a UTF-8 string using the specified encoding type.
  """
  @spec decode_string(binary(), string_encoding()) :: binary()
  def decode_string(str, :ascii), do: String.replace(str, ~r/[^\x00-\x7F]/, "")
  def decode_string(str, :extended_ascii), do: String.replace(str, ~r/[^\x00-\xFF]/, "")
  def decode_string(str, :utf16), do: convert_str(str, :utf16, :utf8)

  defp convert_str(str, in_enc, out_enc) when is_binary(str) do
    case :unicode.characters_to_binary(str, in_enc, out_enc) do
      binary when is_binary(binary) -> binary
      _ -> str
    end
  end

  @doc """
  Encodes a string encoding type to a byte value.

  Uses the representation defined in the Node Naming and User Credential command
  classes.
  """
  @spec encode_string_encoding(string_encoding()) :: 0x00 | 0x01 | 0x02
  def encode_string_encoding(:ascii), do: 0x00
  def encode_string_encoding(:extended_ascii), do: 0x01
  def encode_string_encoding(:utf16), do: 0x02

  @doc "Decodes a string encoding type from a byte value."
  @spec decode_string_encoding(byte()) :: string_encoding() | :unknown
  def decode_string_encoding(0x00), do: :ascii
  def decode_string_encoding(0x01), do: :extended_ascii
  def decode_string_encoding(0x02), do: :utf16
  def decode_string_encoding(_), do: :unknown

  @doc """
  Encodes a duration in seconds into a duration byte.

  Durations of 0..127 seconds are encoded with 1-second resolution. Durations of
  128..7560 seconds are encoded with 1-minute resolution, **rounded to the nearest
  minute**. Larger durations are not supported and will be encoded as unknown (0xFE).

  Some command classes also support a device-default duration (0xFF), which can
  be specified using `:default`.

  ## Examples

      iex> encode_duration(0)
      0x00
      iex> encode_duration(45)
      0x2D
      iex> encode_duration(127)
      0x7F
      iex> encode_duration(128)
      0x81
      iex> encode_duration(180)
      0x82
      iex> encode_duration(200)
      0x82
      iex> encode_duration(7560)
      0xFD
      iex> encode_duration(8000)
      0xFE
      iex> encode_duration(:unknown)
      0xFE
      iex> encode_duration(:default)
      0xFF
  """
  @spec encode_duration(duration()) :: byte()
  def encode_duration(secs) when secs < 0, do: 0
  def encode_duration(secs) when secs in 0..127, do: secs
  def encode_duration(secs) when secs in 128..@max_duration, do: round(secs / 60) + 0x7F
  def encode_duration(:unknown), do: 0xFE
  def encode_duration(:default), do: 0xFF
  def encode_duration(_), do: 0xFE

  @doc """
  Decodes a duration as encoded by `encode_duration/1`. Returns `:unknown` if
  the value is outside the range 0x00..0xFD or `:default` for 0xFF.

  ## Examples

      iex> decode_duration(0x00)
      0
      iex> decode_duration(0x2D)
      45
      iex> decode_duration(0x7F)
      127
      iex> decode_duration(0x80)
      60
      iex> decode_duration(0x81)
      120
      iex> decode_duration(0x82)
      180
      iex> decode_duration(0xFD)
      7560
      iex> decode_duration(0xFE)
      :unknown
      iex> decode_duration(0xFF)
      :default
  """
  @spec decode_duration(byte()) :: duration()
  def decode_duration(byte) when byte in 0x00..0x7F, do: byte
  def decode_duration(byte) when byte in 0x80..0xFD, do: (byte - 0x7F) * 60
  def decode_duration(0xFF), do: :default
  def decode_duration(_), do: :unknown

  @doc """
  Encodes a list of keys into a bitmask using the provided `Grizzly.ZWave.ZWEnum`
  to map keys to bit positions.

  ## Examples

      iex> enum = Grizzly.ZWave.ZWEnum.new(foo: 1, bar: 2, baz: 7, qux: 8)
      iex> encode_enum_bitmask(enum, [:foo, :baz, :qux])
      <<0b10000010, 0b1>>
  """
  @spec encode_enum_bitmask(ZWEnum.t(), list(ZWEnum.k()), encode_bitmask_opts()) :: bitstring()
  def encode_enum_bitmask(%ZWEnum{} = enum, keys, opts \\ []) do
    keys
    |> Enum.reduce([], fn key, acc ->
      case ZWEnum.fetch(enum, key) do
        {:ok, bit_position} -> [bit_position | acc]
        :error -> acc
      end
    end)
    |> encode_bitmask(opts)
  end

  @doc """
  Decodes a list of keys from a bitmask using the provided `Grizzly.ZWave.ZWEnum`
  to map keys to bit positions.

  ## Examples

      iex> enum = Grizzly.ZWave.ZWEnum.new(foo: 1, bar: 2, baz: 7, qux: 8)
      iex> decode_enum_bitmask(enum, <<0b10000010, 0b1>>)
      [:foo, :baz, :qux]
  """
  @spec decode_enum_bitmask(ZWEnum.t(), bitstring()) :: list(ZWEnum.k())
  def decode_enum_bitmask(%ZWEnum{} = enum, bitmask) do
    bitmask
    |> decode_bitmask()
    |> Enum.reduce([], fn key, acc ->
      case ZWEnum.fetch_key(enum, key) do
        {:ok, key} -> [key | acc]
        :error -> acc
      end
    end)
    |> Enum.reverse()
  end

  @doc """
  Encodes a list into a bitmask.

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

  @spec door_lock_modes() :: ZWEnum.t()
  def door_lock_modes() do
    ZWEnum.new(%{
      :unsecured => 0x00,
      :unsecured_with_timeout => 0x01,
      :unsecured_inside_door_handles => 0x10,
      :unsecured_inside_door_handles_with_timeout => 0x11,
      :unsecured_outside_door_handles => 0x20,
      :unsecured_outside_door_handles_with_timeout => 0x21,
      :secured => 0xFF,
      :unknown => 0xFE
    })
  end

  @spec humidity_control_operating_states() :: ZWEnum.t()
  def humidity_control_operating_states() do
    ZWEnum.new(%{
      :idle => 0x00,
      :humidifying => 0x01,
      :dehumidifying => 0x02
    })
  end

  @spec humidity_control_modes() :: ZWEnum.t()
  def humidity_control_modes() do
    ZWEnum.new(%{
      :off => 0x00,
      :humidify => 0x01,
      :dehumidify => 0x02,
      :auto => 0x03
    })
  end

  @spec humidity_control_setpoint_types() :: ZWEnum.t()
  def humidity_control_setpoint_types() do
    ZWEnum.new(%{
      :humidify => 0x01,
      :dehumidify => 0x02,
      :auto => 0x03
    })
  end

  @spec humidity_control_setpoint_scales() :: ZWEnum.t()
  def humidity_control_setpoint_scales() do
    ZWEnum.new(%{
      :percentage => 0x00,
      :absolute => 0x01
    })
  end

  @spec network_update_request_statuses() :: ZWEnum.t()
  def network_update_request_statuses() do
    ZWEnum.new(%{
      :done => 0x00,
      :abort => 0x01,
      :wait => 0x02,
      :disabled => 0x03,
      :overflow => 0x04
    })
  end

  @spec power_levels() :: ZWEnum.t()
  def power_levels() do
    ZWEnum.new(%{
      normal_power: 0x00,
      minus1dBm: 0x01,
      minus2dBm: 0x02,
      minus3dBm: 0x03,
      minus4dBm: 0x04,
      minus5dBm: 0x05,
      minus6dBm: 0x06,
      minus7dBm: 0x07,
      minus8dBm: 0x08,
      minus9dBm: 0x09
    })
  end

  @spec tz_offset_signs() :: ZWEnum.t()
  def tz_offset_signs() do
    ZWEnum.new(%{
      :plus => 0,
      :minus => 1
    })
  end

  @spec user_code_keypad_modes() :: ZWEnum.t()
  def user_code_keypad_modes() do
    ZWEnum.new(%{
      :normal => 0x00,
      :vacation => 0x01,
      :privacy => 0x02,
      :lockout => 0x03
    })
  end

  @spec uc_credential_types() :: ZWEnum.t()
  def uc_credential_types() do
    ZWEnum.new(%{
      none: 0x00,
      pin_code: 0x01,
      password: 0x02,
      rfid: 0x03,
      ble: 0x04,
      nfc: 0x05,
      uwb: 0x06,
      eye_biometric: 0x07,
      face_biometric: 0x08,
      finger_biometric: 0x09,
      hand_biometric: 0x0A,
      unspecified_biometric: 0x0B
    })
  end

  @spec uc_association_set_statuses() :: ZWEnum.t()
  def uc_association_set_statuses() do
    ZWEnum.new(%{
      success: 0x00,
      credential_type_invalid: 0x01,
      credential_slot_invalid: 0x02,
      credential_slot_empty: 0x03,
      destination_user_id_invalid: 0x04,
      destination_user_id_nonexistent: 0x05
    })
  end

  @spec uc_admin_pin_code_set_statuses() :: ZWEnum.t()
  def uc_admin_pin_code_set_statuses() do
    ZWEnum.new(%{
      modified: 0x01,
      unmodified: 0x03,
      response_to_get: 0x04,
      duplicate: 0x07,
      manufacturer_security_rules: 0x08,
      admin_code_not_supported: 0x0D,
      deactivation_not_supported: 0x0E,
      unspecified_error: 0x0F
    })
  end

  @spec kex_fail_types() :: ZWEnum.t()
  def kex_fail_types() do
    ZWEnum.new(%{
      none: 0x00,
      key: 0x01,
      scheme: 0x02,
      curves: 0x03,
      decrypt: 0x05,
      cancel: 0x06,
      auth: 0x07,
      get: 0x08,
      verify: 0x09,
      report: 0x0A
    })
  end

  @spec security_key_types() :: ZWEnum.t()
  def security_key_types() do
    ZWEnum.new(%{
      s0: 0x80,
      s2_access_control: 0x04,
      s2_authenticated: 0x02,
      s2_unauthenticated: 0x01
    })
  end

  @spec binary_sensor_types() :: ZWEnum.t()
  def binary_sensor_types() do
    ZWEnum.new(%{
      general_purpose: 0x01,
      smoke: 0x02,
      co: 0x03,
      co2: 0x04,
      heat: 0x05,
      water: 0x06,
      freeze: 0x07,
      tamper: 0x08,
      aux: 0x09,
      door_window: 0x0A,
      tilt: 0x0B,
      motion: 0x0C,
      glass_break: 0x0D
    })
  end

  @spec multilevel_sensor_types() :: ZWEnum.t()
  def multilevel_sensor_types() do
    ZWEnum.new(%{
      general_purpose: 0x01,
      smoke: 0x02,
      co: 0x03,
      co2: 0x04,
      heat: 0x05,
      water: 0x06,
      freeze: 0x07,
      tamper: 0x08,
      aux: 0x09,
      door_window: 0x0A,
      tilt: 0x0B,
      motion: 0x0C,
      glass_break: 0x0D
    })
  end

  @spec thermostat_fan_modes() :: ZWEnum.t()
  def thermostat_fan_modes() do
    ZWEnum.new(%{
      auto_low: 0x00,
      low: 0x01,
      auto_high: 0x02,
      high: 0x03,
      auto_medium: 0x04,
      medium: 0x05,
      circulation: 0x06,
      humidity_circulation: 0x07,
      left_right: 0x08,
      up_down: 0x09,
      quiet: 0x0A,
      external_circulation: 0x0B
    })
  end

  @spec thermostat_fan_states() :: ZWEnum.t()
  def thermostat_fan_states() do
    ZWEnum.new(%{
      off: 0x00,
      running: 0x01,
      running_high: 0x02,
      running_medium: 0x03,
      circulation: 0x04,
      humidity_circulation: 0x05,
      right_left_circulation: 0x06,
      up_down_circulation: 0x07,
      quiet_circulation: 0x08
    })
  end

  def thermostat_operating_states() do
    ZWEnum.new(%{
      idle: 0x00,
      heating: 0x01,
      cooling: 0x02,
      fan_only: 0x03,
      pending_heat: 0x04,
      pending_cool: 0x05,
      vent_economizer: 0x06,
      aux_heating: 0x07,
      heating_stage_2: 0x08,
      cooling_stage_2: 0x09,
      aux_heat_stage_2: 0x0A,
      aux_heat_stage_3: 0x0B
    })
  end

  def string_encodings() do
    ZWEnum.new(%{
      ascii: 0x00,
      extended_ascii: 0x01,
      utf16: 0x02
    })
  end

  def credential_learn_statuses() do
    ZWEnum.new(
      started: 0x00,
      success: 0x01,
      already_in_progress: 0x02,
      ended_not_due_to_timeout: 0x03,
      timeout: 0x04,
      learn_step_retry: 0x05,
      invalid_add_operation: 0xFE,
      invalid_modify_operation: 0xFF
    )
  end
end
