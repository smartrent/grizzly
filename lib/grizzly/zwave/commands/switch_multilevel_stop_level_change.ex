defmodule Grizzly.ZWave.Commands.SwitchMultilevelStopLevelChange do
  @moduledoc """
   Module for the SWITCH_MULTILEVEL_STOP_LEVEL_CHANGE

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

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
