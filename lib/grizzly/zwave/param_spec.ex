defmodule Grizzly.ZWave.ParamSpec do
  @moduledoc """
  Specification for a single parameter in a Z-Wave command.

  A `ParamSpec` defines how a single field in a command is encoded to and decoded
  from binary format. It specifies the parameter's type, size, default value,
  and any special behavior like conditional presence or computed values.

  ## Core Concepts

  ### Parameter Types

  - `:int` / `:uint` - Signed/unsigned integers with specified bit size
  - `:binary` - Raw binary data (variable or fixed length)
  - `:boolean` - True/false encoded as 0/1 or 0x00/0xFF
  - `:enum` - Symbolic names mapped to numeric values via `ZWEnum`
  - `:bitmask` - Multiple boolean flags packed into one value
  - `:list` - Variable-length repeating items
  - `:constant` - Fixed value (validated but not in command params)
  - `:marker` - Fixed separator bytes (e.g., 0x00 between sections)
  - `:reserved` - Padding/reserved bits
  - `:dsk` - Device-Specific Key encoding
  - `:any` - Custom encode/decode functions

  ### Size Specification

  - `size: N` - Fixed size in bits (must be multiple of 8 for full bytes)
  - `size: :variable` - Consumes all remaining bytes (must be last)
  - `size: {:variable, :length_param}` - Size determined by another parameter

  ### Advanced Features

  #### Conditional Presence (`:when`)

  Parameters can be conditionally present based on other parameter values:

      param(:extended_info, :binary, size: 16,
        when: {:field_equals, :version, 2})

  **Supported conditions:**
  - `{:field_equals, field, value}` - Field must equal value
  - `{:field_not_equals, field, value}` - Field must not equal value
  - `{:field_empty, field}` - Field is nil, [], or ""
  - `{:field_not_empty, field}` - Field has a value
  - `{Module, :function}` - Custom condition function

  #### Computed Values (`:compute`)

  Values can be computed from other parameters instead of being supplied:

      param(:checksum, :uint, size: 8,
        compute: {ChecksumModule, :calculate})

  The compute function receives all command parameters and returns the value.

  #### Variable-Length Fields

  Three patterns for variable-length data:

  1. **Size from another parameter:**
     ```
     param(:length, {:length, :data}, size: 8)  # Encodes byte size of :data
     param(:data, :binary, size: {:variable, :length})
     ```

  2. **Remaining bytes:**
     ```
     param(:data, :binary, size: :variable)  # Must be last parameter
     ```

  3. **Lists with length prefix:**
     ```
     list(:items, item_type: :uint, item_size: 8, prefix_size: 8)
     ```

  ## Examples

      # Simple unsigned integer
      %ParamSpec{name: :value, type: :uint, size: 8, required: true}

      # Enumerated value
      %ParamSpec{
        name: :mode,
        type: :enum,
        size: 8,
        opts: [values: ZWEnum.new(off: 0, heat: 1, cool: 2)]
      }

      # Conditional field
      %ParamSpec{
        name: :user_code,
        type: :binary,
        size: :variable,
        when: {:field_equals, :status, :enabled}
      }

      # Computed field
      %ParamSpec{
        name: :checksum,
        type: :uint,
        size: 8,
        compute: {ChecksumHelper, :calculate}
      }

  ## Encoding Process

  When encoding a command:
  1. Check if parameter should be present (`:when` condition)
  2. Get value (from params, compute function, or default)
  3. Validate value type and range
  4. Convert to binary according to type
  5. Ensure encoded size matches specification

  ## Decoding Process

  When decoding a binary:
  1. Check if parameter should be present (`:when` condition)
  2. Extract appropriate number of bits from binary
  3. Convert bits to Elixir value according to type
  4. Validate decoded value
  5. Add to parameter list or skip based on `opts`

  ## See Also

  - `Grizzly.ZWave.Commands.Generic` - Uses ParamSpecs for encoding/decoding
  - `Grizzly.ZWave.CommandSpec` - Contains list of ParamSpecs for a command
  - `Grizzly.ZWave.Macros` - DSL for creating ParamSpecs declaratively
  """

  import Integer, only: [is_even: 1]

  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.DSK
  alias Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.ZWEnum

  schema =
    NimbleOptions.new!(
      name: [
        type: :atom,
        doc: "The parameter's name",
        required: true
      ],
      type: [
        type:
          {:in,
           [:int, :uint, :boolean, :binary, :enum, :constant, :dsk, :custom, :any, :list, :marker]},
        doc: "The parameter's type",
        required: true
      ],
      size: [
        type:
          {:or,
           [
             :non_neg_integer,
             {:in, [:variable]},
             {:tuple, [{:in, [:variable]}, :non_neg_integer]}
           ]},
        default: 8,
        doc: "The size of the parameter in bits, or :variable for variable length"
      ],
      default: [
        type: :any
      ],
      required: [
        type: :boolean,
        default: true
      ],
      opts: [
        type: :keyword_list,
        default: []
      ],
      when: [
        type: :any,
        doc:
          "Condition for when field should be present. Can be a tuple like {:field_equals, field, value} or {Module, :function} MFA"
      ],
      compute: [
        type: :any,
        doc:
          "MFA tuple {Module, :function} or {Module, :function, args} to compute field value based on other params"
      ]
    )

  @schema schema

  @type type ::
          :int
          | :uint
          | :boolean
          | :binary
          | :enum
          | :constant
          | :reserved
          | :bitmask
          | :marker
          | :list
          | {:length, atom()}
          | :any

  @type when_condition ::
          {:field_equals, atom(), any()}
          | {:field_not_equals, atom(), any()}
          | {:field_empty, atom()}
          | {:field_not_empty, atom()}
          | {module(), atom()}
          | {module(), atom(), list()}

  @type compute_spec ::
          {module(), atom()}
          | {module(), atom(), list()}

  @type list_length ::
          :remaining
          | {:fixed, non_neg_integer()}
          | {:field, atom()}
          | :prefixed

  @type t :: %__MODULE__{
          name: atom(),
          type: type(),
          size: non_neg_integer() | :variable,
          default: any(),
          required: boolean(),
          opts: keyword(),
          when: when_condition() | nil,
          compute: compute_spec() | nil
        }

  defstruct name: nil,
            type: nil,
            size: 8,
            default: nil,
            required: true,
            opts: [],
            when: nil,
            compute: nil

  @doc "Validate a command spec."
  def validate(%__MODULE__{} = spec) do
    spec
    |> Map.from_struct()
    |> NimbleOptions.validate(@schema)
  end

  @doc "Validate a command spec, raising on error."
  def validate!(%__MODULE__{} = spec) do
    spec
    |> Map.from_struct()
    |> NimbleOptions.validate!(@schema)
  end

  @doc """
  Returns the size of the parameter in bits (or :variable) for variable-length params.

  ## Examples

      iex> spec = %Grizzly.ZWave.ParamSpec{type: :uint, size: 16}
      iex> Grizzly.ZWave.ParamSpec.num_bits(spec)
      16

      iex> spec = %Grizzly.ZWave.ParamSpec{type: :binary, size: 32}
      iex> Grizzly.ZWave.ParamSpec.num_bits(spec)
      32

      iex> spec = %Grizzly.ZWave.ParamSpec{type: :int, size: :variable}
      iex> Grizzly.ZWave.ParamSpec.num_bits(spec)
      :variable

      iex> spec = %Grizzly.ZWave.ParamSpec{type: :int, size: {:variable, :another_param}}
      iex> Grizzly.ZWave.ParamSpec.num_bits(spec)
      :variable
  """
  @spec num_bits(t()) :: non_neg_integer() | :variable
  def num_bits(%__MODULE__{size: size}) when is_integer(size), do: size
  def num_bits(%__MODULE__{size: :variable}), do: :variable
  def num_bits(%__MODULE__{size: {:variable, _}}), do: :variable

  @doc """
  Takes the number of bits specified by the param spec from the front of the bitstring.

  Returns `{:ok, {value, rest}}` where `value` is the taken bits and `rest` is the
  remaining bits. If there are not enough bits to take, an error is returned.

  ## Examples

      iex> spec = %Grizzly.ZWave.ParamSpec{type: :uint, size: 8}
      iex> Grizzly.ZWave.ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03>>, [])
      {:ok, {8, <<0x01>>, <<0x02, 0x03>>}}

      iex> spec = %Grizzly.ZWave.ParamSpec{type: :int, size: 16}
      iex> Grizzly.ZWave.ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03>>, [])
      {:ok, {16, <<0x01, 0x02>>, <<0x03>>}}

      iex> spec = %Grizzly.ZWave.ParamSpec{type: :int, size: :variable}
      iex> Grizzly.ZWave.ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03>>, [])
      {:ok, {24, <<0x01, 0x02, 0x03>>, <<>>}}

      iex> spec = %Grizzly.ZWave.ParamSpec{type: :int, size: {:variable, :length_param}}
      iex> Grizzly.ZWave.ParamSpec.take_bits(spec, <<0x01, 0x02, 0x03>>, length_param: 2)
      {:ok, {16, <<0x01, 0x02>>, <<0x03>>}}
  """
  @spec take_bits(t(), bitstring(), keyword()) ::
          {:ok, {bits_taken :: non_neg_integer(), value :: bitstring(), rest :: bitstring()}}
          | {:error, DecodeError.t()}
  def take_bits(param_spec, bitstring, other_params)

  def take_bits(%__MODULE__{type: type, size: size}, bitstring, _other_params)
      when type in [:binary, :dsk] and is_integer(size) and rem(size, 8) == 0 and
             bit_size(bitstring) >= size do
    <<value::bitstring-size(size), rest::bitstring>> = bitstring
    {:ok, {size, value, rest}}
  end

  def take_bits(%__MODULE__{type: :binary, size: size} = param, bitstring, _other_params)
      when is_integer(size) do
    {:error,
     %DecodeError{
       param: param.name,
       value: bitstring,
       reason: "not enough bits to decode parameter"
     }}
  end

  def take_bits(%__MODULE__{type: :marker, size: size}, bitstring, _other_params)
      when bit_size(bitstring) >= size do
    <<value::bitstring-size(size), rest::bitstring>> = bitstring
    {:ok, {size, value, rest}}
  end

  def take_bits(%__MODULE__{type: :list} = param_spec, bitstring, other_params) do
    length_spec = Keyword.get(param_spec.opts, :length, :remaining)
    item_size = Keyword.get(param_spec.opts, :item_size, 8)

    case length_spec do
      :prefixed ->
        # Read length prefix first (default 1 byte)
        prefix_size = Keyword.get(param_spec.opts, :prefix_size, 8)

        case bitstring do
          <<length::size(prefix_size), data::bitstring-size(length * 8), rest::bitstring>> ->
            # For prefixed lists, take everything - decoding will handle the details
            {:ok, {bit_size(bitstring), data, rest}}

          _ ->
            {:error,
             %DecodeError{
               param: param_spec.name,
               value: bitstring,
               reason: "not enough bits for length prefix"
             }}
        end

      {:fixed, n} ->
        # Take exactly n items worth of bits
        total_bits = n * item_size

        if bit_size(bitstring) >= total_bits do
          <<value::bitstring-size(total_bits), rest::bitstring>> = bitstring
          {:ok, {total_bits, value, rest}}
        else
          {:error,
           %DecodeError{
             param: param_spec.name,
             value: bitstring,
             reason: "not enough bits for fixed-length list"
           }}
        end

      {:field, field_name} ->
        # Get length from another field
        case Keyword.fetch(other_params, field_name) do
          {:ok, length} when is_integer(length) ->
            total_bits = length * item_size

            if bit_size(bitstring) >= total_bits do
              <<value::bitstring-size(total_bits), rest::bitstring>> = bitstring
              {:ok, {total_bits, value, rest}}
            else
              {:error,
               %DecodeError{
                 param: param_spec.name,
                 value: bitstring,
                 reason: "not enough bits for list of length #{length}"
               }}
            end

          _ ->
            raise "List length field #{field_name} not found in params or is not an integer"
        end

      :remaining ->
        # Take all remaining bits
        {:ok, {bit_size(bitstring), bitstring, <<>>}}
    end
  end

  def take_bits(
        %__MODULE__{size: {:variable, length_param}} = param_spec,
        bitstring,
        other_params
      ) do
    length_in_bits =
      case Keyword.fetch(other_params, length_param) do
        {:ok, length_in_bytes} when is_integer(length_in_bytes) ->
          length_in_bytes * 8

        _ ->
          raise ArgumentError,
                "Length parameter #{length_param} not found in other_params or is not an integer"
      end

    # Change type to :any to avoid hitting binary-specific clauses which expect size in bytes
    take_bits(%__MODULE__{param_spec | type: :any, size: length_in_bits}, bitstring, other_params)
  end

  def take_bits(%__MODULE__{size: :variable}, bitstring, _other_params) do
    {:ok, {bit_size(bitstring), bitstring, <<>>}}
  end

  def take_bits(%__MODULE__{size: size}, bitstring, _other_params)
      when is_integer(size) and bit_size(bitstring) >= size do
    <<value::bitstring-size(size), rest::bitstring>> = bitstring
    {:ok, {size, value, rest}}
  end

  def take_bits(%__MODULE__{} = param, bitstring, _other_params) do
    {:error,
     %DecodeError{
       param: param.name,
       value: bitstring,
       reason: "not enough bits to decode parameter"
     }}
  end

  @doc """
  Whether the parameter should be included in the resulting list of parameters
  when decoding a command.
  """
  @spec include_when_decoding?(t()) :: boolean()
  def include_when_decoding?(param_spec) do
    param_spec.opts[:hidden] != true and param_spec.type != :reserved and
      param_spec.type != :marker
  end

  @doc """
  Checks if a parameter should be present based on its `when` condition.
  """
  @spec should_be_present?(t(), keyword()) :: boolean()
  def should_be_present?(%__MODULE__{when: nil}, _params), do: true

  def should_be_present?(%__MODULE__{when: condition}, params) do
    evaluate_condition(condition, params)
  end

  @doc """
  Computes the value for a parameter using its `compute` function.
  Returns `{:ok, value}` if computed, or `:error` if no compute function.
  """
  @spec compute_value(t(), keyword()) :: {:ok, any()} | :error
  def compute_value(%__MODULE__{compute: nil}, _params), do: :error

  def compute_value(%__MODULE__{compute: {mod, fun}}, params) do
    {:ok, apply(mod, fun, [params])}
  end

  def compute_value(%__MODULE__{compute: {mod, fun, args}}, params) do
    {:ok, apply(mod, fun, [params | args])}
  end

  defp evaluate_condition({:field_equals, field, value}, params) do
    Keyword.get(params, field) == value
  end

  defp evaluate_condition({:field_not_equals, field, value}, params) do
    Keyword.get(params, field) != value
  end

  defp evaluate_condition({:field_empty, field}, params) do
    case Keyword.get(params, field) do
      nil -> true
      [] -> true
      "" -> true
      _ -> false
    end
  end

  defp evaluate_condition({:field_not_empty, field}, params) do
    case Keyword.get(params, field) do
      nil -> false
      [] -> false
      "" -> false
      _ -> true
    end
  end

  defp evaluate_condition({mod, fun}, params) when is_atom(mod) and is_atom(fun) do
    apply(mod, fun, [params])
  end

  defp evaluate_condition({mod, fun, args}, params) when is_atom(mod) and is_atom(fun) do
    apply(mod, fun, [params | args])
  end

  @doc """
  Encodes an Elixir term into a bitstring according to the parameter specification.
  """
  @spec encode_value(t(), term(), keyword()) :: bitstring()
  def encode_value(param_spec, value, other_params \\ [])

  def encode_value(%__MODULE__{type: :enum, size: size} = spec, value, _) do
    values_map = Keyword.fetch!(spec.opts, :values)

    <<ZWEnum.fetch!(values_map, value)::size(size)>>
  end

  def encode_value(%__MODULE__{type: :bitmask, size: :variable} = spec, value, _)
      when is_list(value) do
    values_map = Keyword.fetch!(spec.opts, :values)
    Encoding.encode_enum_bitmask(values_map, value)
  end

  def encode_value(%__MODULE__{type: :bitmask, size: size} = spec, value, _)
      when is_list(value) and is_integer(size) and (rem(size, 8) == 0 or size < 8) do
    values_map = Keyword.fetch!(spec.opts, :values)
    full_bitmask = Encoding.encode_enum_bitmask(values_map, value, min_bytes: div(size, 8))

    # Only truncate to size if the size is less than 8 bytes. Multi-byte bitmasks
    # are always byte-aligned.
    if size < 8 do
      <<_truncated::size(8 - size), right_sized_bitmask::bitstring-size(size)>> = full_bitmask
      right_sized_bitmask
    else
      full_bitmask
    end
  end

  def encode_value(%__MODULE__{type: :any, size: size} = spec, value, _) do
    encoder = Keyword.get(spec.opts, :encode)

    result =
      if is_function(encoder, 1) do
        encoder.(value)
      else
        raise "No valid encoder function for enum param #{spec.name}"
      end

    result =
      case result do
        {:ok, v} ->
          v

        {:error, _} ->
          raise "Error encoding enum param #{spec.name} with value: #{inspect(value)}"

        v ->
          v
      end

    case result do
      v when is_integer(v) -> <<v::size(size)>>
      v when is_binary(v) or is_bitstring(v) -> v
      _ -> raise "Invalid value for enum param #{spec.name}: #{inspect(result)}"
    end
  end

  def encode_value(%__MODULE__{type: :int} = param_spec, value, other_params)
      when is_integer(value) do
    size = encoded_size(param_spec, value, other_params)
    <<value::signed-size(size)>>
  end

  def encode_value(%__MODULE__{type: :uint} = param_spec, value, other_params)
      when is_integer(value) do
    size = encoded_size(param_spec, value, other_params)
    <<value::size(size)>>
  end

  def encode_value(%__MODULE__{type: :boolean, size: size} = param_spec, value, _)
      when is_boolean(value) do
    cond do
      Keyword.has_key?(param_spec.opts, value) ->
        <<param_spec.opts[value]::size(size)>>

      value == false ->
        <<0::size(size)>>

      true ->
        <<0xFF::size(size)>>
    end
  end

  def encode_value(%__MODULE__{type: :constant, size: size} = param_spec, _, _) do
    <<param_spec.opts[:value]::size(size)>>
  end

  def encode_value(%__MODULE__{type: :reserved, size: size}, _, _) do
    <<0::size(size)>>
  end

  def encode_value(%__MODULE__{type: :binary, size: size}, value, _)
      when is_bitstring(value) and is_integer(size) do
    <<value::bitstring-size(size)>>
  end

  def encode_value(%__MODULE__{type: :binary, size: :variable}, value, _)
      when is_bitstring(value) do
    value
  end

  def encode_value(%__MODULE__{type: :marker, size: size} = param_spec, _, _) do
    marker_value = Keyword.get(param_spec.opts, :value, 0x00)
    <<marker_value::size(size)>>
  end

  def encode_value(%__MODULE__{type: :list} = param_spec, value, other_params)
      when is_list(value) do
    item_type = Keyword.fetch!(param_spec.opts, :item_type)
    item_size = Keyword.get(param_spec.opts, :item_size, 8)
    length_spec = Keyword.get(param_spec.opts, :length, :remaining)

    # Build a temp param spec for encoding each item
    item_spec = %__MODULE__{
      name: :list_item,
      type: item_type,
      size: item_size,
      opts: Keyword.get(param_spec.opts, :item_opts, [])
    }

    encoded_items =
      for item <- value, into: <<>> do
        encode_value(item_spec, item, other_params)
      end

    case length_spec do
      :prefixed ->
        # Encode length prefix (default to 1 byte)
        prefix_size = Keyword.get(param_spec.opts, :prefix_size, 8)
        <<length(value)::size(prefix_size)>> <> encoded_items

      _ ->
        encoded_items
    end
  end

  def encode_value(%__MODULE__{type: :dsk, size: size}, value, _) when is_integer(size) do
    case value do
      %DSK{raw: raw} ->
        <<raw::bitstring-size(size)>>

      bin when is_binary(value) and byte_size(value) > 16 ->
        <<DSK.parse!(bin).raw::bitstring-size(size)>>

      bin when is_binary(value) and byte_size(value) <= 16 and is_even(byte_size(value)) ->
        <<DSK.new(bin).raw::bitstring-size(size)>>
    end
  end

  def encode_value(
        %__MODULE__{type: {:length, other_param}, size: size} = _spec,
        _value,
        other_params
      ) do
    length_value =
      case Keyword.fetch(other_params, other_param) do
        {:ok, v} when is_binary(v) -> byte_size(v)
        {:ok, _} -> raise "Cannot encode length of non-binary parameter"
        _ -> raise "Cannot encode length of #{inspect(other_param)}: parameter not found"
      end

    <<length_value::size(size)>>
  end

  def encode_value(
        %__MODULE__{type: :binary, size: {:variable, other_param}},
        value,
        other_params
      )
      when is_bitstring(value) do
    expected_size =
      case Keyword.fetch(other_params, other_param) do
        {:ok, length_in_bytes} when is_integer(length_in_bytes) -> length_in_bytes
        _ -> raise "Length parameter #{other_param} not found in params or is not an integer"
      end

    actual_size = bit_size(value)

    if actual_size != expected_size do
      raise "Binary parameter size mismatch: expected #{expected_size} bits, got #{actual_size} bits"
    end

    value
  end

  defp encoded_size(%__MODULE__{size: size}, _value, _other_params)
       when is_integer(size) do
    size
  end

  defp encoded_size(
         %__MODULE__{size: {:variable, length_param}},
         _value,
         other_params
       ) do
    case Keyword.fetch(other_params, length_param) do
      {:ok, length_in_bytes} when is_integer(length_in_bytes) ->
        length_in_bytes * 8

      _ ->
        raise "Length parameter #{length_param} not found in params or is not an integer: #{inspect(other_params)}"
    end
  end

  @doc """
  Decodes an Elixir term from a bitstring according to the parameter specification.
  """
  @spec decode_value(t(), bitstring()) :: {:ok, term()} | {:error, DecodeError.t()}
  def decode_value(param_spec, bitstring, other_params \\ [])

  def decode_value(%__MODULE__{type: :uint, size: size} = param_spec, binary, _other_params) do
    case binary do
      <<v::size(^size)>> ->
        {:ok, v}

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: :int, size: size} = param_spec, binary, _other_params) do
    case binary do
      <<v::signed-size(^size)>> -> {:ok, v}
      _ -> {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: :enum, size: size} = param_spec, binary, _other_params) do
    values_map = Keyword.fetch!(param_spec.opts, :values)

    case binary do
      <<raw_value::size(^size)>> ->
        case ZWEnum.fetch_key(values_map, raw_value) do
          {:ok, value} ->
            {:ok, value}

          :error ->
            case param_spec.opts[:if_unknown] do
              :raw -> {:ok, raw_value}
              {:value, default_value} -> {:ok, default_value}
              _ -> {:error, %DecodeError{param: param_spec.name, value: raw_value}}
            end
        end

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: :bitmask, size: size} = param_spec, binary, _other_params) do
    values_map = Keyword.fetch!(param_spec.opts, :values)

    case binary do
      <<raw_value::bitstring-size(^size)>> ->
        # Ensure we're byte-aligned
        raw_value =
          if rem(bit_size(raw_value), 8) != 0 do
            <<0::size(8 - rem(bit_size(raw_value), 8)), raw_value::bitstring>>
          else
            raw_value
          end

        decoded_values = Encoding.decode_enum_bitmask(values_map, raw_value)
        {:ok, decoded_values}

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: :marker, size: size} = param_spec, binary, _other_params) do
    expected_value = Keyword.get(param_spec.opts, :value, 0x00)

    case binary do
      <<^expected_value::size(^size)>> ->
        {:ok, expected_value}

      <<actual::size(^size)>> ->
        {:error,
         %DecodeError{
           param: param_spec.name,
           value: actual,
           reason: "Expected marker value #{expected_value}, got #{actual}"
         }}

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: :list} = param_spec, binary, other_params) do
    item_type = Keyword.fetch!(param_spec.opts, :item_type)
    item_size = Keyword.get(param_spec.opts, :item_size, 8)
    length_spec = Keyword.get(param_spec.opts, :length, :remaining)

    # Build a temp param spec for decoding each item
    item_spec = %__MODULE__{
      name: :list_item,
      type: item_type,
      size: item_size,
      opts: Keyword.get(param_spec.opts, :item_opts, [])
    }

    with {:ok, {list_length, data_to_decode}} <-
           determine_list_length(length_spec, binary, other_params, item_size, param_spec.name) do
      decode_list_items(item_spec, data_to_decode, list_length, [], other_params)
    end
  end

  def decode_value(%__MODULE__{type: :any, size: size} = param_spec, binary, _other_params) do
    decoder = Keyword.get(param_spec.opts, :decode)

    case binary do
      <<raw_value::size(^size)>> ->
        if is_function(decoder, 1) do
          case decoder.(raw_value) do
            {:ok, v} ->
              {:ok, v}

            {:error, %DecodeError{}} = err ->
              err

            {:error, _} ->
              {:error, %DecodeError{param: param_spec.name, value: raw_value}}

            v ->
              {:ok, v}
          end
        else
          {:ok, raw_value}
        end

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: :constant} = param_spec, _binary, _other_params) do
    {:ok, param_spec.opts[:value]}
  end

  def decode_value(%__MODULE__{type: :reserved}, _binary, _other_params) do
    {:ok, nil}
  end

  def decode_value(%__MODULE__{type: :boolean, size: size} = param_spec, binary, _other_params) do
    case binary do
      <<v::size(^size)>> -> {:ok, v != 0}
      _ -> {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: {:length, _}} = param_spec, binary, other_params) do
    decode_value(%__MODULE__{param_spec | type: :uint}, binary, other_params)
  end

  def decode_value(%__MODULE__{type: :binary, size: size} = param_spec, binary, _other_params)
      when is_integer(size) do
    case binary do
      <<v::bitstring-size(size)>> ->
        {:ok, v}

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: :binary, size: :variable}, binary, _other_params) do
    {:ok, binary}
  end

  def decode_value(%__MODULE__{type: :dsk}, binary, _other_params) do
    {:ok, DSK.new(binary)}
  end

  def decode_value(
        %__MODULE__{type: :binary, size: {:variable, length_param}} = spec,
        binary,
        other_params
      ) do
    length =
      case Keyword.fetch(other_params, length_param) do
        {:ok, v} when is_integer(v) ->
          v

        _ ->
          {:error,
           %DecodeError{
             param: spec.name,
             value: nil,
             reason: "Length parameter #{inspect(length_param)} not found or is not an integer"
           }}
      end

    {:ok, <<binary::bitstring-size(length)>>}
  end

  def decode_value(%__MODULE__{} = param_spec, _binary, _other_params) do
    raise "Decoding for param type #{inspect(param_spec.type)} not implemented for param #{param_spec.name}"
  end

  # Private helper functions for list decoding

  defp determine_list_length(:remaining, binary, _other_params, item_size, _param_name)
       when rem(bit_size(binary), item_size) == 0 do
    {:ok, {div(bit_size(binary), item_size), binary}}
  end

  defp determine_list_length(:remaining, binary, _other_params, item_size, param_name) do
    {:error,
     %DecodeError{
       param: param_name,
       value: binary,
       reason: "Binary size #{bit_size(binary)} is not a multiple of item size #{item_size}"
     }}
  end

  defp determine_list_length({:fixed, n}, binary, _other_params, item_size, param_name) do
    expected_bits = n * item_size

    if bit_size(binary) >= expected_bits do
      {:ok, {n, binary}}
    else
      {:error,
       %DecodeError{
         param: param_name,
         value: binary,
         reason: "Expected at least #{expected_bits} bits for fixed list of #{n} items"
       }}
    end
  end

  defp determine_list_length({:field, field_name}, binary, other_params, _item_size, param_name) do
    case Keyword.fetch(other_params, field_name) do
      {:ok, length} when is_integer(length) ->
        {:ok, {length, binary}}

      _ ->
        {:error,
         %DecodeError{
           param: param_name,
           value: other_params,
           reason: "List length field #{field_name} not found in params or is not an integer"
         }}
    end
  end

  defp determine_list_length(
         {:prefixed, prefix_size},
         binary,
         other_params,
         item_size,
         param_name
       )
       when is_integer(prefix_size) and prefix_size > 0 do
    case binary do
      <<length::size(prefix_size), rest::binary>> ->
        {:ok, {length, rest}}

      _ ->
        # Fall back to the generic :prefixed error handling
        determine_list_length(:prefixed, binary, other_params, item_size, param_name)
    end
  end

  defp determine_list_length(:prefixed, binary, _other_params, _item_size, param_name) do
    {:error,
     %DecodeError{
       param: param_name,
       value: binary,
       reason: "Not enough data for length prefix"
     }}
  end

  defp decode_list_items(_item_spec, _binary, 0, acc, _other_params) do
    {:ok, Enum.reverse(acc)}
  end

  defp decode_list_items(item_spec, binary, remaining, acc, other_params) do
    with {:ok, {_size, value, rest}} <- take_bits(item_spec, binary, other_params),
         {:ok, decoded_value} <- decode_value(item_spec, value, other_params) do
      decode_list_items(item_spec, rest, remaining - 1, [decoded_value | acc], other_params)
    end
  end
end
