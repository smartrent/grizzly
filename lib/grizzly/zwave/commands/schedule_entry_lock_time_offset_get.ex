defmodule Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetGet do
  @moduledoc """
  This command is used to request time zone offset and daylight savings parameters.

  Params:
    - none

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, []}
  def decode_params(_binary) do
    {:ok, []}
  end
end
