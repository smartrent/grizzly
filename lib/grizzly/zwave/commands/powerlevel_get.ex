defmodule Grizzly.ZWave.Commands.PowerlevelGet do
  @moduledoc """
  This command is used to request the current power level value.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Powerlevel

  @impl true
  def new(params) do
    command = %Command{
      name: :powerlevel_get,
      command_byte: 0x02,
      command_class: Powerlevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
