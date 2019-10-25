defmodule Grizzly.Command.Encoding do
  @moduledoc "Utility module to validate command arguments prior to command encoding"

  alias Grizzly.Command.EncodeError
  require Logger

  @type size :: non_neg_integer | atom
  @type sizable :: :bits | :bytes
  @type specs ::
          spec
          | [specs]
          | {:encode_with, atom}
          | {:encode_with, atom, atom}
          | {:encode_in_context_with, atom, atom}
          | {:range, integer, integer}
          | %{required(atom) => specs}
  @type spec ::
          :byte
          | :byte
          | :integer
          | :positive_integer
          | :binary
          | :bit
          | {sizable, size}
          | {[specs], size}
  @spec encode_and_validate_args(struct(), %{required(atom()) => specs}, [atom()]) ::
          {:ok, struct()} | {:error, EncodeError.t()}
  @doc "Verifies that the (sub)arguments of a command, possibly after encoding, meet the given type specs"
  def encode_and_validate_args(command, type_specs, sub_arguments_path \\ []) do
    command_module = command.__struct__

    Enum.reduce_while(
      type_specs,
      {:ok, command},
      fn {arg_name, specs}, {:ok, acc} ->
        case arg_value(command, sub_arguments_path, arg_name) do
          nil ->
            _ =
              Logger.warn(
                "Command arg #{inspect(arg_name)} not found for specs #{inspect(specs)}"
              )

            error = EncodeError.new({:invalid_argument_value, arg_name, nil, command_module})

            {:halt, {:error, error}}

          value ->
            case validate_arg(specs, value, command) do
              {:ok, maybe_encoded_value} ->
                {:cont, {:ok, Map.put(acc, arg_name, maybe_encoded_value)}}

              _ ->
                error =
                  EncodeError.new({:invalid_argument_value, arg_name, value, command_module})

                {:halt, {:error, error}}
            end
        end
      end
    )
  end

  defp arg_value(args, [], arg_name) do
    Map.get(args, arg_name)
  end

  defp arg_value(args, [sub | rest], arg_name) do
    Map.get(args, sub) |> arg_value(rest, arg_name)
  end

  defp validate_arg(:bit, value, _command) when value in 0..1 do
    {:ok, value}
  end

  defp validate_arg(:byte, value, _command) when value in 0..255 do
    {:ok, value}
  end

  defp validate_arg(:integer, value, _command) when is_integer(value) do
    {:ok, value}
  end

  defp validate_arg(:positive_integer, value, _command) when is_integer(value) and value >= 0 do
    {:ok, value}
  end

  defp validate_arg(:binary, value, _command) when is_binary(value) do
    {:ok, value}
  end

  defp validate_arg({:bits, n}, value, _command)
       when is_integer(n) and is_integer(value) do
    max = :math.pow(2, n) |> round()

    if value in 0..max do
      {:ok, value}
    else
      {:error, :invalid_arg, value}
    end
  end

  defp validate_arg({:bytes, n}, value, _command)
       when is_integer(n) and is_integer(value) do
    max = round(:math.pow(2, n * 8)) - 1

    if value in 0..max do
      {:ok, value}
    else
      {:error, :invalid_arg, value}
    end
  end

  defp validate_arg({[spec], n}, value, command) when is_integer(n) and is_list(value) do
    if Enum.count(value) == n do
      validate_arg([spec], value, command)
    else
      {:error, :invalid_arg, value}
    end
  end

  defp validate_arg({sizable, field}, value, command)
       when sizable in [:bits, :bytes] and is_atom(field) and is_integer(value) do
    case Map.get(command, field) do
      nil ->
        {:error, :invalid_arg, value}

      n when is_integer(n) ->
        validate_arg({sizable, n}, value, command)

      _ ->
        {:error, :invalid_arg, value}
    end
  end

  defp validate_arg([spec], value_list, command) when is_list(value_list) do
    results =
      Enum.reduce_while(
        value_list,
        {:ok, []},
        fn value, {:ok, acc} ->
          case validate_arg(spec, value, command) do
            {:ok, maybe_encoded_value} ->
              {:cont, {:ok, [maybe_encoded_value | acc]}}

            error ->
              {:halt, error}
          end
        end
      )

    case results do
      {:ok, list} ->
        {:ok, Enum.reverse(list)}

      error ->
        error
    end
  end

  defp validate_arg(specs_map, value_map, command) when is_map(specs_map) and is_map(value_map) do
    Enum.reduce_while(
      value_map,
      {:ok, %{}},
      fn {key, val}, {:ok, acc} ->
        case Map.get(specs_map, key) do
          nil ->
            {:halt, {:error, :invalid_arg, value_map}}

          specs ->
            case validate_arg(specs, val, command) do
              {:ok, maybe_encoded_val} ->
                {:cont, {:ok, Map.put(acc, key, maybe_encoded_val)}}

              {:error, :invalid_arg, _} ->
                {:halt, {:error, :invalid_arg, value_map}}
            end
        end
      end
    )
  end

  defp validate_arg({:range, low, high}, value, _command) when is_number(value) do
    if value >= low and value <= high, do: {:ok, value}, else: {:error, :invalid_arg, value}
  end

  defp validate_arg({:range, _low, _high}, value, _command) do
    {:error, :invalid_arg, value}
  end

  defp validate_arg({:encode_with, encode_method}, value, command) do
    command_module = command.__struct__
    apply(command_module, encode_method, [value])
  end

  defp validate_arg({:encode_with, module, encode_method}, value, _command) do
    apply(module, encode_method, [value])
  end

  defp validate_arg({:encode_in_context_with, module, encode_method}, value, command) do
    apply(module, encode_method, [value, Map.from_struct(command)])
  end

  defp validate_arg(_spec, value, _command) do
    {:error, :invalid_arg, value}
  end
end
