defmodule Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingReport do
  @moduledoc """
  ScheduleEntryLockDailyRepeatingReport command is used to return the requested
  schedule slot ID for identified user

  Params:

    * `:user_identifier` - The User Identifier is used to recognize the user
      identity. A valid User Identifier MUST be a value starting from 1 to the
      maximum number of users supported by the device
    * `:schedule_slot_id` - A value from 1 to Number of Slots Daily Repeating
      Supported
    * `:week_days` - a list of scheduled week day's names
    * `:start_hour` - A value from 0 to 23 representing the starting hour of
      the time fence.
    * `:start_minute` - A value from 0 to 59 representing the starting minute of
      the time fence.
    * `:duration_hour` - A value from 0 to 23 representing how many hours the
      time fence will last
    * `:duration_minute` - A value from 0 to 59 representing how many minutes
      the time fence will last past the Duration Hour field.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @type param ::
          {:user_identifier, byte()}
          | {:schedule_slot_id, byte()}
          | {:week_days, [ScheduleEntryLock.week_day()]}
          | {:start_hour, 0..23}
          | {:start_minute, 0..59}
          | {:duration_hour, 0..23}
          | {:duration_minute, 0..59}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :schedule_entry_lock_daily_repeating_report,
      command_byte: 0x0F,
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
    week_days = Command.param!(command, :week_days)
    start_hour = Command.param!(command, :start_hour)
    start_minute = Command.param!(command, :start_minute)
    duration_hour = Command.param!(command, :duration_hour)
    duration_minute = Command.param!(command, :duration_minute)

    week_day_bitmask = ScheduleEntryLock.weekdays_to_bitmask(week_days)

    <<user_identifier, schedule_slot_id>> <>
      week_day_bitmask <> <<start_hour, start_minute, duration_hour, duration_minute>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<user_identifier, schedule_slot_id, week_day_bitmask, start_hour, start_minute,
          duration_hour, duration_minute>>
      ) do
    week_days = ScheduleEntryLock.bitmask_to_weekdays(week_day_bitmask)

    {:ok,
     [
       user_identifier: user_identifier,
       schedule_slot_id: schedule_slot_id,
       week_days: week_days,
       start_hour: start_hour,
       start_minute: start_minute,
       duration_hour: duration_hour,
       duration_minute: duration_minute
     ]}
  end
end
