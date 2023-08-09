defmodule Grizzly.ZWave.Commands.S2CommandsSupportedGet do
  @moduledoc """
  Query the commands supported by a node when using S2.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security2

  @impl Grizzly.ZWave.Command
  @spec new([]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :s2_commands_supported_get,
      command_byte: 0x0D,
      command_class: Security2,
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
