defmodule Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingGet do
  @moduledoc """
  ScheduleEntryLockDailyRepeatingGet command is used to request a daily
  repeating schedule slot for a identified user and specified schedule slot ID.

  Params:
  * `:user_identifier` is used to recognize the user identity. A valid User
    Identifier MUST be a value starting from 1 to the maximum number of users supported by the device;
  * `:schedule_slot_id` a value from 1 to Number of Slots Daily Repeating Supported.
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
