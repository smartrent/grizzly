defmodule Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetGet do
  @moduledoc """
  This command is used to request time zone offset and daylight savings parameters.

  Params:
    - none

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :schedule_entry_lock_time_offset_get,
      command_byte: 0x0B,
      command_class: ScheduleEntryLock,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, []}
  def decode_params(_binary) do
    {:ok, []}
  end
end
