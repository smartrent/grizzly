defmodule Grizzly.ZWave.Commands.MasterCodeGet do
  @moduledoc """
  MasterCodeGet gets the master code

  Params:

    * `:code` - a 4 - 10 master code pin in string format (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @impl Command
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :master_code_get,
      command_byte: 0x0F,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Command
  @spec decode_params(binary()) :: {:ok, keyword()}
  def decode_params(_) do
    {:ok, []}
  end
end
