defmodule Grizzly.ZWave.Commands.TimeOffsetGet do
  @moduledoc """
  This command is used to request the Time Zone Offset (TZO) and Daylight Savings Time (DST)
   parameters from a supporting node.

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
