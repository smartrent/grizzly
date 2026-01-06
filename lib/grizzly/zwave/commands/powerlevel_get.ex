defmodule Grizzly.ZWave.Commands.PowerlevelGet do
  @moduledoc """
  This command is used to request the current power level value.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Powerlevel

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :powerlevel_get,
      command_byte: 0x02,
      command_class: Powerlevel,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
