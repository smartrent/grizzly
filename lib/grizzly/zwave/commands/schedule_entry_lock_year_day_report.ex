defmodule Grizzly.ZWave.Commands.ScheduleEntryLockYearDayReport do
  @moduledoc """
  The ScheduleEntryLockYearDayReport command returns year/day schedule report for the requested schedule slot ID for the identified user.

  Params:

    * `:user_identifier` - The User Identifier is used to recognize the user identity.

    * `:schedule_slot_id` - A value from 1 to Number of Slots Daily Repeating Supported

    * `:start_year` - A value from 0 to 99 that represents the 2 year in the century.

    * `:start_month` - A value from 1 to 12 that represents the month in a year.

    * `:start_day` - A value from 1 to 31 that represents the date of the month

    * `:start_hour` - A value from 0 to 23 representing the starting hour of the time fence.

    * `:start_minute` - A value from 0 to 59 representing the starting minute of the time fence.

    * `:stop_year` - A value from 0 to 99 that represents the 2 year in the century.

    * `:stop_month` - A value from 1 to 12 that represents the month in a year.

    * `:stop_day` - A value from 1 to 31 that represents the date of the month.

    * `:stop_hour` - A value from 0 to 23 representing the stop hour of the time fence.

    * `:stop_minute` - A value from 0 to 59 representing the stop minute of the time fence

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:user_identifier, byte()}
          | {:schedule_slot_id, byte()}
          | {:start_year, 0..99}
          | {:start_month, 1..12}
          | {:start_day, 1..31}
          | {:start_hour, 0..23}
          | {:start_minute, 0..59}
          | {:stop_year, 0..99}
          | {:stop_month, 1..12}
          | {:stop_day, 1..31}
          | {:stop_hour, 0..23}
          | {:stop_minute, 0..59}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :schedule_entry_lock_year_day_report,
      command_byte: 0x08,
      command_class: ScheduleEntryLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_identifier = Command.param!(command, :user_identifier)
    schedule_slot_id = Command.param!(command, :schedule_slot_id)
    start_year = Command.param!(command, :start_year)
    start_month = Command.param!(command, :start_month)
    start_day = Command.param!(command, :start_day)
    start_hour = Command.param!(command, :start_hour)
    start_minute = Command.param!(command, :start_minute)
    stop_year = Command.param!(command, :stop_year)
    stop_month = Command.param!(command, :stop_month)
    stop_day = Command.param!(command, :stop_day)
    stop_hour = Command.param!(command, :stop_hour)
    stop_minute = Command.param!(command, :stop_minute)

    <<user_identifier, schedule_slot_id, start_year, start_month, start_day, start_hour,
      start_minute, stop_year, stop_month, stop_day, stop_hour, stop_minute>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<user_identifier, schedule_slot_id, start_year, start_month, start_day, start_hour,
          start_minute, stop_year, stop_month, stop_day, stop_hour, stop_minute>>
      ) do
    {:ok,
     [
       user_identifier: user_identifier,
       schedule_slot_id: schedule_slot_id,
       start_year: start_year,
       start_month: start_month,
       start_day: start_day,
       start_hour: start_hour,
       start_minute: start_minute,
       stop_year: stop_year,
       stop_month: stop_month,
       stop_day: stop_day,
       stop_hour: stop_hour,
       stop_minute: stop_minute
     ]}
  end
end
