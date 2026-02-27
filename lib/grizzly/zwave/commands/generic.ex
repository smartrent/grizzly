defmodule Grizzly.ZWave.Commands.Generic do
  @moduledoc """
  Generic encoder and decoder for Z-Wave commands using declarative specifications.

  This module implements the `Grizzly.ZWave.Command` behavior to provide automatic
  encoding and decoding of commands based on their parameter specifications. It
  traverses the parameter list sequentially, encoding or decoding each field according
  to its `ParamSpec`.

  ## Encoding Process

  Parameters are encoded in order:
  1. Check if parameter should be present (`:when` condition)
  2. Get parameter value (from command, compute function, or default)
  3. Encode value according to parameter type
  4. Append to binary accumulator
  5. Stop when reaching first non-present optional parameter (unless conditional)

  ## Decoding Process

  Binary is decoded sequentially:
  1. Check if parameter should be present (`:when` condition)
  2. Extract bits according to parameter size
  3. Decode value according to parameter type
  4. Add to decoded parameters list
  5. Continue until all parameters processed or binary exhausted

  ## Examples

      # Encoding a simple command
      spec = %CommandSpec{params: [param(:value, :uint, size: 8)]}
      cmd = %Command{params: [value: 42]}
      Generic.encode_params(spec, cmd)
      #=> <<42>>

      # Decoding a command
      spec = %CommandSpec{params: [param(:value, :uint, size: 8)]}
      Generic.decode_params(spec, <<42>>)
      #=> {:ok, [value: 42]}

  This module is used automatically when commands in `Grizzly.ZWave.Commands` specify
  `Cmds.Generic` as their implementation module.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandSpec
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.ParamSpec

  @impl Grizzly.ZWave.Command
  def encode_params(spec, cmd) do
    encode_param_list(spec.params, cmd, [])
  end

  @doc false
  # Recursively encodes each parameter in the list, accumulating binary parts
  defp encode_param_list([], _cmd, binary_parts) do
    # Reverse the parts list and concatenate into final binary
    for bitstring <- Enum.reverse(binary_parts), into: <<>>, do: bitstring
  end

  defp encode_param_list([{name, param_spec} | remaining_params], cmd, binary_parts) do
    # Check if this field should be present based on when condition
    if ParamSpec.should_be_present?(param_spec, cmd.params) do
      value = get_param_value(param_spec, cmd, name)

      # Stop encoding when we reach an optional field that isn't present
      # (unless it has a when condition, which allows gaps in parameter presence)
      if should_stop_encoding?(param_spec, cmd.params, name, value) do
        encode_param_list([], cmd, binary_parts)
      else
        encoded_value = ParamSpec.encode_value(param_spec, value, cmd.params)

        # For {:length, other_param} types, update cmd with the computed length
        # so the target parameter can reference it via {:variable, length_param}
        cmd = maybe_store_length(param_spec, cmd, name, value)

        encode_param_list(remaining_params, cmd, [encoded_value | binary_parts])
      end
    else
      encode_param_list(remaining_params, cmd, binary_parts)
    end
  end

  # Gets the parameter value from various sources (computed, required, default)
  defp get_param_value(param_spec, cmd, name) do
    cond do
      # Special case: length parameters encode the byte size of another param
      match?({:length, _}, param_spec.type) ->
        {:length, other_param} = param_spec.type
        other_value = Command.param!(cmd, other_param)
        byte_size(other_value)

      # Try to compute the value if a compute function is provided
      param_spec.compute != nil ->
        case ParamSpec.compute_value(param_spec, cmd.params) do
          {:ok, computed} -> computed
          :error -> Keyword.get(cmd.params, name, param_spec.default)
        end

      # Required parameters must be present (except special types)
      param_spec.required and param_spec.type not in [:constant, :reserved, :marker] ->
        Command.param!(cmd, name)

      # Optional parameters use default if not present
      true ->
        Keyword.get(cmd.params, name, param_spec.default)
    end
  end

  # Determines if encoding should stop at this parameter
  defp should_stop_encoding?(param_spec, params, name, _value) do
    not Keyword.has_key?(params, name) and
      param_spec.required == false and
      param_spec.when == nil
  end

  # For {:length, _} parameters, store the bit length in the command for later use
  defp maybe_store_length(%{type: {:length, _}} = _param_spec, cmd, name, byte_length) do
    # Store as bit length since other params reference it with {:variable, length_param}
    Command.put_param(cmd, name, byte_length * 8)
  end

  defp maybe_store_length(_param_spec, cmd, _name, _value), do: cmd

  @impl Grizzly.ZWave.Command
  def decode_params(%CommandSpec{} = spec, binary) do
    decode_param_list(spec.params, binary, [])
  end

  @doc false
  # Base case: Successfully decoded all parameters
  defp decode_param_list([], _binary, decoded_params) do
    # Return in original order (params were accumulated in reverse)
    {:ok, Enum.reverse(decoded_params)}
  end

  # Handle end of binary before end of parameter list
  defp decode_param_list([{name, param_spec} | remaining_params], <<>>, decoded_params) do
    cond do
      # Skip conditional fields that shouldn't be present
      not ParamSpec.should_be_present?(param_spec, decoded_params) ->
        decode_param_list(remaining_params, <<>>, decoded_params)

      # Required fixed-size fields must be present
      param_spec.required and param_spec.size != :variable ->
        {:error, %DecodeError{param: name, value: nil, reason: "unexpected end of command"}}

      # Variable-size binary fields can be empty
      param_spec.type == :binary and param_spec.size == :variable ->
        decode_param_list(remaining_params, <<>>, [{name, <<>>} | decoded_params])

      # Other required fields must be present
      param_spec.required ->
        {:error, %DecodeError{param: name, value: nil, reason: "unexpected end of command"}}

      # Optional fields can be omitted
      true ->
        decode_param_list(remaining_params, <<>>, [{name, nil} | decoded_params])
    end
  end

  # Decode the next parameter from the binary
  defp decode_param_list([{name, param_spec} | remaining_params], binary, decoded_params) do
    # Check if this field should be present based on when condition
    if ParamSpec.should_be_present?(param_spec, decoded_params) do
      # Extract the appropriate number of bits and decode the value
      with {:ok, {actual_size, raw_value, rest}} <-
             ParamSpec.take_bits(param_spec, binary, decoded_params),
           {:ok, decoded_value} <-
             ParamSpec.decode_value(%{param_spec | size: actual_size}, raw_value, decoded_params) do
        # Some parameters shouldn't be included in the final result
        if ParamSpec.include_when_decoding?(param_spec) do
          decode_param_list(remaining_params, rest, [{name, decoded_value} | decoded_params])
        else
          decode_param_list(remaining_params, rest, decoded_params)
        end
      end
    else
      decode_param_list(remaining_params, binary, decoded_params)
    end
  end
end
