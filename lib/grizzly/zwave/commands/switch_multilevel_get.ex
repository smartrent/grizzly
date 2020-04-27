defmodule Grizzly.ZWave.Commands.SwitchMultilevelGet do
  @moduledoc """
  Module for the SWITCH_MULTILEVEL_GET

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SwitchMultilevel

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :switch_multilevel_get,
      command_byte: 0x02,
      command_class: SwitchMultilevel,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def decode_params(_), do: {:ok, []}

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end
end
