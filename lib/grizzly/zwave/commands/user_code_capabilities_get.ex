defmodule Grizzly.ZWave.Commands.UserCodeCapabilitiesGet do
  @moduledoc """
  This command is used to request the User Code capabilities of a node.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode
  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.Command
  @spec new([]) :: {:ok, Command.t()}
  def new(_) do
    command = %Command{
      name: :user_code_capabilities_get,
      command_byte: 0x06,
      command_class: UserCode,
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
  @spec decode_params(binary()) :: {:ok, []} | {:error, DecodeError.t()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
