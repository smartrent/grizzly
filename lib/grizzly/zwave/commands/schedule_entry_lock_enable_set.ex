defmodule Grizzly.ZWave.Commands.ScheduleEntryLockEnableSet do
  @moduledoc """
  This command enables or disables schedules for a specified user code ID.

  Params:

    * `:user_identifier` - The User Identifier is used to recognize the user identity.

    * `:enabled` - Indicates whether the schedule for the user is enabled or disabled

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @type param :: {:user_identifier, byte()} | {:enabled, boolean()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :schedule_entry_lock_enable_set,
      command_byte: 0x01,
      command_class: ScheduleEntryLock,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_identifier = Command.param!(command, :user_identifier)
    enabled = Command.param!(command, :enabled)
    status = status_to_byte(enabled)
    <<user_identifier, status>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<user_identifier, enabled>>) do
    {:ok, [user_identifier: user_identifier, enabled: byte_to_status(enabled)]}
  end

  defp status_to_byte(true), do: 0x01
  defp status_to_byte(false), do: 0x00

  defp byte_to_status(0x01), do: true
  defp byte_to_status(0x00), do: false
end
