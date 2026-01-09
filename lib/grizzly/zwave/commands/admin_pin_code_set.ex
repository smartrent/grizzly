defmodule Grizzly.ZWave.Commands.AdminPinCodeSet do
  @moduledoc """
  AdminPinCodeSet is used to set the admin code at the receiving node.

  ## Parameters

  * `:code` - the admin code (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @type param :: {:code, binary()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    code = Command.param!(command, :code) |> binary_slice(0, 15)
    <<0::4, byte_size(code)::4, code::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_::4, length::4, code::binary-size(length)>>) do
    {:ok, [code: code]}
  end
end
