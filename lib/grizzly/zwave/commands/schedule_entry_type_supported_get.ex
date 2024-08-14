defmodule Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedGet do
  @moduledoc """
  This command is used to request the number of schedule slots each type of schedule the device supports for every user.

  Params:
    - none

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :schedule_entry_type_supported_get,
      command_byte: 0x09,
      command_class: ScheduleEntryLock,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
