defmodule Grizzly.ZWave.Commands.ScheduleEntryLockWeekDaySet do
  @moduledoc """
  This command set or erase a weekday schedule for a identified user who already has valid user access code.

  Params:

    * `:set_action` - Indicates whether to erase or modify

    * `:user_identifier` - The User Identifier is used to recognize the user identity.

    * `:schedule_slot_id` - A value from 1 to Number of Slots Daily Repeating Supported

    * `:day_of_week` - A value from 0 to 6 where 0 is Sunday.

    * `:start_hour` - A value from 0 to 23 representing the starting hour of the time fence.

    * `:start_minute` - A value from 0 to 59 representing the starting minute of the time fence.

    * `:stop_hour` - A value from 0 to 23 representing the stop hour of the time fence.

    * `:stop_minute` - A value from 0 to 59 representing the stop minute of the time fence

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @type param ::
          {:set_action, :erase | :modify}
          | {:user_identifier, byte()}
          | {:schedule_slot_id, byte()}
          | {:day_of_week, 0..6}
          | {:start_hour, 0..23}
          | {:start_minute, 0..59}
          | {:stop_hour, 0..23}
          | {:stop_minute, 0..59}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :schedule_entry_lock_week_day_set,
      command_byte: 0x03,
      command_class: ScheduleEntryLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    set_action = Command.param!(command, :set_action)
    user_identifier = Command.param!(command, :user_identifier)
    schedule_slot_id = Command.param!(command, :schedule_slot_id)
    day_of_week = Command.param!(command, :day_of_week)
    start_hour = Command.param!(command, :start_hour)
    start_minute = Command.param!(command, :start_minute)
    stop_hour = Command.param!(command, :stop_hour)
    stop_minute = Command.param!(command, :stop_minute)

    action_byte = action_to_byte(set_action)

    <<action_byte, user_identifier, schedule_slot_id, day_of_week, start_hour, start_minute,
      stop_hour, stop_minute>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<action_byte, user_identifier, schedule_slot_id, day_of_week, start_hour, start_minute,
          stop_hour, stop_minute>>
      ) do
    {:ok,
     [
       set_action: byte_to_action(action_byte),
       user_identifier: user_identifier,
       schedule_slot_id: schedule_slot_id,
       day_of_week: day_of_week,
       start_hour: start_hour,
       start_minute: start_minute,
       stop_hour: stop_hour,
       stop_minute: stop_minute
     ]}
  end

  defp action_to_byte(:erase), do: 0x00
  defp action_to_byte(:modify), do: 0x01

  defp byte_to_action(0x00), do: :erase
  defp byte_to_action(0x01), do: :modify
end
