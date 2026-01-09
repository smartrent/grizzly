defmodule Grizzly.ZWave.Commands.SwitchMultilevelGet do
  @moduledoc """
  Module for the SWITCH_MULTILEVEL_GET

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def decode_params(_), do: {:ok, []}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end
end
