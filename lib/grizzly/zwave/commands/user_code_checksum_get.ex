defmodule Grizzly.ZWave.Commands.UserCodeChecksumGet do
  @moduledoc """
  What does this command do??

  Params:

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @impl Grizzly.ZWave.Command
  @spec new([]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :user_code_checksum_get,
      command_byte: 0x11,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, []}
  def decode_params(_binary) do
    {:ok, []}
  end
end
