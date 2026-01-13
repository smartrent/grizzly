defmodule Grizzly.ZWave.Commands.AdminCodeSetReport do
  @moduledoc """
  AdminCodeSet sets the admin code

  Params:

    * `:code` - a 4 - 10 admin code pin in string format (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:code, String.t()}

  @impl Command
  def encode_params(_spec, command) do
    code = Command.param!(command, :code)

    <<0::4, byte_size(code)::4>> <> code
  end

  @impl Command
  def decode_params(_spec, <<_::4, _length::4, code_binary::binary>>) do
    {:ok, code: code_binary}
  end
end
