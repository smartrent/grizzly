defmodule Grizzly.ZWave.Commands.ScheduleEntryLockWeekDayGet do
  @moduledoc """
  The ScheduleEntryLockWeekDayGet command gets a week day schedule slot for a identified user and specified schedule slot ID.

  Params:

    * `:user_identifier` - The User Identifier is used to recognize the user identity.

    * `:schedule_slot_id` - A value from 1 to Number of Slots Daily Repeating Supported

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:user_identifier, byte()} | {:schedule_slot_id, byte()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    user_identifier = Command.param!(command, :user_identifier)
    schedule_slot_id = Command.param!(command, :schedule_slot_id)
    <<user_identifier, schedule_slot_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<user_identifier, schedule_slot_id>>) do
    {:ok, [user_identifier: user_identifier, schedule_slot_id: schedule_slot_id]}
  end
end
