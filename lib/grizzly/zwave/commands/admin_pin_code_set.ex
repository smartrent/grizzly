defmodule Grizzly.ZWave.Commands.AdminPinCodeSet do
  @moduledoc """
  AdminPinCodeSet is used to set the admin code at the receiving node.

  ## Parameters

  * `:code` - the admin code (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:code, binary()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    code = Command.param!(command, :code) |> binary_slice(0, 15)
    <<0::4, byte_size(code)::4, code::binary>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_::4, length::4, code::binary-size(length)>>) do
    {:ok, [code: code]}
  end
end
