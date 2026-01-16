defmodule Grizzly.ZWave.Commands.Generic do
  @moduledoc """
  Generic encoder and decoder for Z-Wave commands.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandSpec
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.ParamSpec

  @impl Grizzly.ZWave.Command
  def encode_params(spec, cmd) do
    do_encode_params(spec.params, cmd, [])
  end

  # Base case: no more params to encode
  defp do_encode_params([], _cmd, parts) do
    for bitstring <- Enum.reverse(parts), into: <<>>, do: bitstring
  end

  # Recursive case: encode the next param
  defp do_encode_params([{name, param_spec} | params], cmd, parts) do
    value =
      if param_spec.required and param_spec.type not in [:constant, :reserved] do
        Command.param!(cmd, name)
      else
        Keyword.get(cmd.params, name, param_spec.default)
      end

    # When we get to a non-required param that is not present, stop encoding
    if not Keyword.has_key?(cmd.params, name) and param_spec.required == false do
      do_encode_params([], cmd, parts)
    else
      parts = [ParamSpec.encode_value(param_spec, value, cmd.params) | parts]
      do_encode_params(params, cmd, parts)
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(%CommandSpec{} = spec, binary) do
    do_decode_params(spec.params, binary, [])
  end

  # Base case: we ran out of params to decode. Doesn't matter if there's anything
  # left in the binary since the spec says to ignore it.
  defp do_decode_params([], _binary, decoded_params), do: {:ok, Enum.reverse(decoded_params)}

  # Alt base case: We ran out of binary before we ran out of params. That's okay
  # if the next param isn't required, but otherwise, we need to error out.
  defp do_decode_params([{name, param_spec} | _params], <<>>, decoded_params) do
    if param_spec.required do
      {:error, %DecodeError{param: name, value: nil, reason: "unexpected end of command"}}
    else
      do_decode_params([], <<>>, decoded_params)
    end
  end

  # Recursive case: Decode the next param
  defp do_decode_params([{name, param_spec} | params], binary, decoded_params) do
    with {:ok, {actual_size, value, rest}} <-
           ParamSpec.take_bits(param_spec, binary, decoded_params),
         {:ok, decoded_value} <- ParamSpec.decode_value(%{param_spec | size: actual_size}, value) do
      if ParamSpec.include_when_decoding?(param_spec) do
        do_decode_params(params, rest, [{name, decoded_value} | decoded_params])
      else
        do_decode_params(params, rest, decoded_params)
      end
    end
  end
end
