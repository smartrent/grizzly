defmodule Grizzly.ZWave.Commands.SecurityCommandsSupportedGet do
  @moduledoc """
  Query the commands supported by a node when using S2.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security

  @impl Grizzly.ZWave.Command
  @spec new([]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :security_commands_supported_get,
      command_byte: 0x02,
      command_class: Security,
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
