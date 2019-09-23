defmodule Grizzly.CommandClass.ScheduleEntryLock.YearDaySet do
  @moduledoc """
  Command for working with SCHEDULE_ENTRY_LOCK command class YEAR_DAY_SET command

  Command Options:
    
    * `:action` - The action either to erase or to modify the slot
    * `:slot_id` - The schedule slot id
    * `:user_id` - The schedule user id for the EntryLock
    * `:start_year` - A value from 0 to 99 that represents the 2 year in the century 
    * `:start_month` - A value from 1 to 12 that represents the month in a year
    * `:start_day` - A value from 1 to 31 that represents the date of the month
    * `:start_hour` - A value from 0 to 23 representing the starting hour of the time fence
    * `:start_minute` - A value from 0 to 59 representing the starting minute of the time fence
    * `:stop_year` - A value from 0 to 99 that represents the 2 year in the century
    * `:stop_month` - A value from 1 to 12 that represents the month in a year
    * `:stop_day` - A value from 1 to 31 that represents the date of the month
    * `:stop_hour` - A value from 0 to 23 representing the starting hour of the time fence
    * `:stop_minute` - A value from 0 to 59 representing the starting minute of the time fence
    * `:seq_number` - The sequence number used in the Z/IP packet
    * `:retries` - The number of attempts to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.ScheduleEntryLock

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          action: ScheduleEntryLock.enable_action(),
          user_id: non_neg_integer,
          slot_id: non_neg_integer,
          start_year: non_neg_integer,
          start_month: non_neg_integer,
          start_day: non_neg_integer,
          start_hour: non_neg_integer,
          start_hour: non_neg_integer,
          start_minute: non_neg_integer,
          stop_year: non_neg_integer,
          stop_month: non_neg_integer,
          stop_day: non_neg_integer,
          stop_hour: non_neg_integer,
          stop_hour: non_neg_integer,
          stop_minute: non_neg_integer
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:user_id, non_neg_integer()}
          | {:slot_id, non_neg_integer()}
          | {:action, ScheduleEntryLock.enable_action()}
          | {:start_year, non_neg_integer()}
          | {:start_month, non_neg_integer()}
          | {:start_hour, non_neg_integer()}
          | {:start_minute, non_neg_integer()}
          | {:stop_year, non_neg_integer()}
          | {:stop_month, non_neg_integer()}
          | {:stop_hour, non_neg_integer()}
          | {:stop_minute, non_neg_integer()}

  defstruct seq_number: nil,
            retries: 2,
            user_id: nil,
            slot_id: nil,
            action: nil,
            start_year: nil,
            start_month: nil,
            start_day: nil,
            start_hour: nil,
            start_minute: nil,
            stop_year: nil,
            stop_month: nil,
            stop_day: nil,
            stop_hour: nil,
            stop_minute: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(
        %__MODULE__{
          user_id: user_id,
          slot_id: slot_id,
          action: _action,
          start_year: _start_year,
          start_month: start_month,
          start_day: start_day,
          start_hour: start_hour,
          start_minute: start_minute,
          stop_year: _stop_year,
          stop_month: stop_month,
          stop_day: stop_day,
          stop_hour: stop_hour,
          stop_minute: stop_minute,
          seq_number: seq_number
        } = command
      ) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             user_id: :byte,
             slot_id: :byte,
             action: {:encode_with, ScheduleEntryLock, :encode_enable_action},
             start_year: {:encode_with, ScheduleEntryLock, :encode_year},
             start_month: {:range, 1, 12},
             start_day: {:range, 1, 31},
             start_hour: {:range, 0, 23},
             start_minute: {:range, 0, 59},
             stop_year: {:encode_with, ScheduleEntryLock, :encode_year},
             stop_month: {:range, 1, 12},
             stop_day: {:range, 1, 31},
             stop_hour: {:range, 0, 23},
             stop_minute: {:range, 0, 59}
           }) do
      binary =
        Packet.header(seq_number) <>
          <<
            0x4E,
            0x06,
            encoded.action::size(8),
            user_id,
            slot_id,
            encoded.start_year,
            start_month,
            start_day,
            start_hour,
            start_minute,
            encoded.stop_year,
            stop_month,
            stop_day,
            stop_hour,
            stop_minute
          >>

      {:ok, binary}
    end
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
            command: :year_day_report,
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
