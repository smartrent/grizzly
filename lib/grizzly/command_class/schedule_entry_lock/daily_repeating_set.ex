defmodule Grizzly.CommandClass.ScheduleEntryLock.DailyRepeatingSet do
  @moduledoc """
  Command for working with SCHEDULE_ENTRY_LOCK command class DAILY_REPEATING_SET command

  Command Options:
    
    * `:user_id` - a number for the user id
    * `:slot_id` - the slot id for the code
    * `:action` - `:enable` or `:disable` the action
    * `:weekdays` - List of weekdays to run schedule on
    * `:start_hour` - The hour of the day to start
    * `:start_minute` - The minute of the hour to start
    * `:duration_hour` - The amount of hours to keep the schedule available
    * `:duration_minute` - The number of minutes within the hour to keep the schedule available
    * `:seq_number` - The sequence number used in the Z/IP packet
    * `:retries` - The number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ScheduleEntryLock

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          user_id: non_neg_integer(),
          slot_id: non_neg_integer(),
          action: ScheduleEntryLock.enable_action(),
          weekdays: ScheduleEntryLock.weekdays(),
          start_hour: non_neg_integer(),
          start_minute: non_neg_integer(),
          duration_hour: non_neg_integer(),
          duration_minute: non_neg_integer()
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:user_id, non_neg_integer()}
          | {:slot_id, non_neg_integer()}
          | {:action, ScheduleEntryLock.enable_action()}
          | {:weekdays, ScheduleEntryLock.weekdays()}
          | {:start_hour, non_neg_integer()}
          | {:start_minute, non_neg_integer()}
          | {:duration_hour, non_neg_integer()}
          | {:duration_minute, non_neg_integer()}

  defstruct seq_number: nil,
            retries: 2,
            user_id: nil,
            slot_id: nil,
            action: nil,
            weekdays: [],
            start_hour: nil,
            start_minute: nil,
            duration_hour: nil,
            duration_minute: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{
        user_id: user_id,
        slot_id: slot_id,
        action: action,
        weekdays: weekdays,
        start_hour: start_hour,
        start_minute: start_minute,
        duration_hour: duration_hour,
        duration_minute: duration_minute,
        seq_number: seq_number
      }) do
    weekdays_mask = ScheduleEntryLock.encode_weekdays(weekdays)
    encoded_action = ScheduleEntryLock.encode_enable_action(action)

    binary =
      Packet.header(seq_number) <>
        <<
          0x4E,
          0x10,
          encoded_action::size(8),
          user_id,
          slot_id,
          weekdays_mask::binary(),
          start_hour,
          start_minute,
          duration_hour,
          duration_minute
        >>

    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, :ok}
          | {:retry, t}
  def handle_response(
        %__MODULE__{seq_number: seq_number} = _command,
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:done, :ok}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: 0},
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: n} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(
        _,
        %Packet{
          body: %{
            command_class: :schedule_entry_lock,
            command: :daily_repeating_report,
            value: report
          }
        }
      ) do
    {:done, {:ok, report}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response, :nack_waiting]
        } = packet
      ) do
    if Packet.sleeping_delay?(packet) do
      {:queued, command}
    else
      {:continue, command}
    end
  end

  def handle_response(command, _), do: {:continue, command}
end
