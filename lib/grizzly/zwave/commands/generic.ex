defmodule Grizzly.ZWave.Commands.Generic do
  @moduledoc """
  Generic encoder and decoder for Z-Wave commands.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.CommandSpec
  alias Grizzly.ZWave.CommandSpec.Param
  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.Command
  def encode_params(spec, cmd) do
    for {name, param_spec} <- spec.params, into: <<>> do
      value = Keyword.get(cmd.params, name, param_spec.default)
      encode_param(param_spec, value)
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(%CommandSpec{} = spec, binary) do
    {decoded, _} =
      Enum.reduce_while(spec.params, {[], binary}, fn
        _, {decoded_params, <<>>} ->
          {:halt, {decoded_params, <<>>}}

        {name, param_spec}, {decoded_params, binary} ->
          with {:ok, {value, rest}} <- take_bits(param_spec, binary),
               {:ok, decoded_value} <- decode_param(param_spec, value) do
            if include_when_decoding?(param_spec) do
              {:cont, {[{name, decoded_value} | decoded_params], rest}}
            else
              {:cont, {decoded_params, rest}}
            end
          else
            err ->
              {:halt, err}
          end
      end)

    case decoded do
      {:error, _} = error -> error
      decoded -> {:ok, Enum.reverse(decoded)}
    end
  end

  @spec encode_param(Param.t(), dynamic()) :: bitstring()
  defp encode_param(%Param{type: :enum, size: size} = spec, value) do
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

  defp encode_param(%Param{type: :int, size: size}, value) when is_integer(value) do
    <<value::signed-size(size)>>
  end

  defp encode_param(%Param{type: :uint, size: size}, value) when is_integer(value) do
    <<value::size(size)>>
  end

  defp encode_param(%Param{type: :boolean, size: size} = param_spec, value)
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

  defp encode_param(%Param{type: :constant, size: size} = param_spec, _value) do
    <<param_spec.opts[:value]::size(size)>>
  end

  defp encode_param(%Param{type: :reserved, size: size} = _param_spec, _value) do
    <<0::size(size)>>
  end

  @spec decode_param(Param.t(), bitstring()) :: {:ok, term()} | {:error, DecodeError.t()}
  defp decode_param(%Param{type: :uint, size: size} = param_spec, binary) do
    case binary do
      <<v::size(^size)>> ->
        {:ok, v}

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  defp decode_param(%Param{type: :int, size: size} = param_spec, binary) do
    case binary do
      <<v::signed-size(^size)>> ->
        {:ok, v}

      _ ->
        {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  defp decode_param(%Param{type: :enum, size: size} = param_spec, binary) do
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

  defp decode_param(%Param{type: :constant} = param_spec, _binary) do
    {:ok, param_spec.opts[:value]}
  end

  defp decode_param(%Param{type: :reserved}, _binary) do
    {:ok, nil}
  end

  defp decode_param(%Param{type: :boolean, size: size} = param_spec, binary) do
    case binary do
      <<v::size(^size)>> -> {:ok, v != 0}
      _ -> {:error, %DecodeError{param: param_spec.name, value: binary}}
    end
  end

  defp decode_param(%Param{} = param_spec, _binary) do
    raise "Decoding for param type #{inspect(param_spec.type)} not implemented for param #{param_spec.name}"
  end

  @spec take_bits(Param.t(), bitstring()) ::
          {:ok, {bitstring(), bitstring()}} | {:error, DecodeError.t()}
  defp take_bits(%Param{size: size}, bitstring) when bit_size(bitstring) >= size do
    <<value::bitstring-size(size), rest::bitstring>> = bitstring
    {:ok, {value, rest}}
  end

  defp take_bits(%Param{} = param, bitstring) do
    {:error, %DecodeError{param: param.name, value: bitstring}}
  end

  defp include_when_decoding?(param_spec) do
    param_spec.opts[:hidden] != true and param_spec.type != :reserved
  end
end
