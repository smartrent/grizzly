defmodule Grizzly.ZWave.Commands.ScheduleEntryLockWeekDayReport do
  @moduledoc """
  This command returns week day schedule report for the requested schedule slot ID for identified user.

  Params:

    * `:user_identifier` - The User Identifier is used to recognize the user identity.

    * `:schedule_slot_id` - A value from 1 to Number of Slots Daily Repeating Supported

    * `:day_of_week` - A value from 0 to 6 where 0 is Sunday.

    * `:start_hour` - A value from 0 to 23 representing the starting hour of the time fence.

    * `:start_minute` - A value from 0 to 59 representing the starting minute of the time fence.

    * `:stop_hour` - A value from 0 to 23 representing the stop hour of the time fence.

    * `:stop_minute` - A value from 0 to 59 representing the stop minute of the time fence

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:user_identifier, byte()}
          | {:schedule_slot_id, byte()}
          | {:day_of_week, 0..6}
          | {:start_hour, 0..23}
          | {:start_minute, 0..59}
          | {:stop_hour, 0..23}
          | {:stop_minute, 0..59}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_identifier = Command.param!(command, :user_identifier)
    schedule_slot_id = Command.param!(command, :schedule_slot_id)
    day_of_week = Command.param!(command, :day_of_week)
    start_hour = Command.param!(command, :start_hour)
    start_minute = Command.param!(command, :start_minute)
    stop_hour = Command.param!(command, :stop_hour)
    stop_minute = Command.param!(command, :stop_minute)

    <<user_identifier, schedule_slot_id, day_of_week, start_hour, start_minute, stop_hour,
      stop_minute>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<user_identifier, schedule_slot_id, day_of_week, start_hour, start_minute, stop_hour,
          stop_minute>>
      ) do
    {:ok,
     [
       user_identifier: user_identifier,
       schedule_slot_id: schedule_slot_id,
       day_of_week: day_of_week,
       start_hour: start_hour,
       start_minute: start_minute,
       stop_hour: stop_hour,
       stop_minute: stop_minute
     ]}
  end
end
