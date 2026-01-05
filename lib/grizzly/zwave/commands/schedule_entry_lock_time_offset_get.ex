defmodule Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetGet do
  @moduledoc """
  This command is used to request time zone offset and daylight savings parameters.

  Params:
    - none

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :schedule_entry_lock_time_offset_get,
      command_byte: 0x0B,
      command_class: ScheduleEntryLock
    }

    {:ok, command}
  end

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
