defmodule Grizzly.ZWave.Commands.ScheduleEntryLockEnableAllSet do
  @moduledoc """
  This command enables or disables all schedules for type Entry Lock.

  Params:

    * `:enabled` - Indicates whether the schedule for the user is enabled or disabled

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:enabled, boolean()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    enabled = Command.param!(command, :enabled)
    status = status_to_byte(enabled)
    <<status>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<enabled>>) do
    {:ok, [enabled: byte_to_status(enabled)]}
  end

  defp status_to_byte(true), do: 0x01
  defp status_to_byte(false), do: 0x00

  defp byte_to_status(0x01), do: true
  defp byte_to_status(0x00), do: false
end
