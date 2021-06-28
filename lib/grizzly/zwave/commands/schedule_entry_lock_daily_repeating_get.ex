defmodule Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingGet do
  @moduledoc """
  ScheduleEntryLockDailyRepeatingGet command is used to request a daily repeating schedule slot for a identified user and specified schedule slot ID.

  Params:
  * `:user_identifier` is used to recognize the user identity. A valid User Identifier MUST be a value starting from 1 to the maximum number of users supported by the device;

  * `:schedule_slot_id` a value from 1 to Number of Slots Daily Repeating Supported.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @type param :: {:user_identifier, byte()} | {:schedule_slot_id, byte()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :schedule_entry_lock_daily_repeating_get,
      command_byte: 0x0E,
      command_class: ScheduleEntryLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_identifier = Command.param!(command, :user_identifier)
    schedule_slot_id = Command.param!(command, :schedule_slot_id)
    <<user_identifier, schedule_slot_id>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<user_identifier, schedule_slot_id>>) do
    {:ok, [user_identifier: user_identifier, schedule_slot_id: schedule_slot_id]}
  end
end
