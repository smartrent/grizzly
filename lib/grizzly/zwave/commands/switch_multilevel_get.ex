defmodule Grizzly.ZWave.Commands.SwitchMultilevelGet do
  @moduledoc """
  Module for the SWITCH_MULTILEVEL_GET

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SwitchMultilevel

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :switch_multilevel_get,
      command_byte: 0x02,
      command_class: SwitchMultilevel,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_), do: {:ok, []}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end
end
