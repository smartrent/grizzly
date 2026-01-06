defmodule Grizzly.ZWave.Commands.SwitchMultilevelStopLevelChange do
  @moduledoc """
   Module for the SWITCH_MULTILEVEL_STOP_LEVEL_CHANGE

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SwitchMultilevel

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :switch_multilevel_stop_level_change,
      command_byte: 0x05,
      command_class: SwitchMultilevel,
      params: []
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
