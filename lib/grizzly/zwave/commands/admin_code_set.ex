defmodule Grizzly.ZWave.Commands.AdminCodeSet do
  @moduledoc """
  AdminCodeSet sets the admin code

  Params:

    * `:code` - a 4 - 10 admin code pin in string format (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type param :: {:code, String.t()}

  @impl Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :admin_code_set,
      command_byte: 0x0E,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    code = Command.param!(command, :code)

    <<0::4, byte_size(code)::4>> <> code
  end

  @impl Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<_::4, _length::4, code_binary::binary>>) do
    {:ok, code: code_binary}
  end
end
