defmodule Grizzly.ZWave.Commands.DateGet do
  @moduledoc """
  This command is used to request the current date adjusted according to the local time zone and
  Daylight Saving Time from a supporting node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
