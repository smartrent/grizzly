defmodule Grizzly.ZWave.ParamSpec do
  @moduledoc """
  Data structure describing a parameter for a Z-Wave command.
  """

  alias Grizzly.ZWave.DecodeError

  schema =
    NimbleOptions.new!(
      name: [
        type: :atom,
        doc: "The parameter's name",
        required: true
      ],
      type: [
        type: {:in, [:int, :uint, :boolean, :binary, :enum, :constant, :reserved, :any]},
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
          | {:length, atom()}
          | :any

  @type t :: %__MODULE__{
          name: atom(),
          type: type(),
          size: non_neg_integer() | :variable,
          default: any(),
          required: boolean(),
          opts: keyword()
        }

  defstruct name: nil,
            type: nil,
            size: 8,
            default: nil,
            required: true,
            opts: []

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

  def take_bits(%__MODULE__{type: :binary, size: size}, bitstring, _other_params)
      when is_integer(size) and rem(size, 8) == 0 and bit_size(bitstring) >= size do
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
    param_spec.opts[:hidden] != true and param_spec.type != :reserved
  end

  @doc """
  Encodes an Elixir term into a bitstring according to the parameter specification.
  """
  @spec encode_value(t(), term(), keyword()) :: bitstring()
  def encode_value(param_spec, value, other_params \\ [])

  def encode_value(%__MODULE__{type: :enum, size: size} = spec, value, _) do
    encoder = Keyword.fetch!(spec.opts, :encode)

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
      <<v::signed-size(^size)>> ->
        {:ok, v}

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  def decode_value(%__MODULE__{type: :enum, size: size} = param_spec, binary, _other_params) do
    decoder = Keyword.fetch!(param_spec.opts, :decode)

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
        {:error, %DecodeError{param: param_spec.name, value: binary, reason: "uwu"}}
    end
  end

  def decode_value(%__MODULE__{type: :binary, size: :variable}, binary, _other_params) do
    {:ok, binary}
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
end
