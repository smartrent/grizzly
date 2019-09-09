defmodule Grizzly.Command.Encoding do
  @moduledoc "Utility module to validate command arguments prior to command encoding"

  alias Grizzly.Command.EncodeError
  require Logger

  @type specs :: spec | [spec] | {:encode_with, atom} | {:encode_with, atom, atom}
  @type spec :: :byte | :integer

  @spec encode_and_validate_args(struct(), %{required(atom()) => specs}) ::
          {:ok, struct()} | {:error, EncodeError.t()}
  @doc "Verifies that the arguments of a command, possibly after encoding, meet the given type specs"
  def encode_and_validate_args(command, type_specs) do
    command_module = command.__struct__

    Enum.reduce_while(
      type_specs,
      {:ok, command},
      fn {arg_name, specs}, {:ok, acc} ->
        case Map.get(command, arg_name) do
          nil ->
            _ =
              Logger.warn(
                "Command arg #{inspect(arg_name)} not found for specs #{inspect(specs)}"
              )

            {:ok, acc}

          value ->
            case validate_arg(specs, value, command_module) do
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

  defp validate_arg(:byte, value, _command_module) when value in 0..255 do
    {:ok, value}
  end

  defp validate_arg(:integer, value, _command_module) when is_integer(value) do
    {:ok, value}
  end

  defp validate_arg([spec], value_list, command_module) when is_list(value_list) do
    results =
      Enum.reduce_while(
        value_list,
        {:ok, []},
        fn value, {:ok, acc} ->
          case validate_arg(spec, value, command_module) do
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

  defp validate_arg({:encode_with, encode_method}, value, command_module) do
    apply(command_module, encode_method, [value])
  end

  defp validate_arg({:encode_with, module, encode_method}, value, _command_module) do
    apply(module, encode_method, [value])
  end

  defp validate_arg(_spec, value, _command_module) do
    {:error, :invalid_arg, value}
  end
end
