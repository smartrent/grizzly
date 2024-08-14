defmodule Grizzly.ZWave.Commands.ScheduleEntryLockEnableAllSet do
  @moduledoc """
  This command enables or disables all schedules for type Entry Lock.

  Params:

    * `:enabled` - Indicates whether the schedule for the user is enabled or disabled

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @type param :: {:enabled, boolean()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :schedule_entry_lock_enable_all_set,
      command_byte: 0x02,
      command_class: ScheduleEntryLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    enabled = Command.param!(command, :enabled)
    status = status_to_byte(enabled)
    <<status>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<enabled>>) do
    {:ok, [enabled: byte_to_status(enabled)]}
  end

  defp status_to_byte(true), do: 0x01
  defp status_to_byte(false), do: 0x00

  defp byte_to_status(0x01), do: true
  defp byte_to_status(0x00), do: false
end
