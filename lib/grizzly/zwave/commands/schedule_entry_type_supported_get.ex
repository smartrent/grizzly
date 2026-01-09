defmodule Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedGet do
  @moduledoc """
  This command is used to request the number of schedule slots each type of schedule the device supports for every user.

  Params:
    - none

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
