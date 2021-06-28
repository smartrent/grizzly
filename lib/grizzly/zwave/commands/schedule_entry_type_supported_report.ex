defmodule Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedReport do
  @moduledoc """
  This command is used to report the number of supported schedule slots an Entry Lock schedule device supports for each user in the system.

  Params:

    * `:number_of_slots_week_day` - A number from 0 – 255 that represents how many different schedule slots are supported each week for every user in the system for type Week Day.

    * `:number_of_slots_year_day` - A number from 0 – 255 that represents how many different schedule slots are supported for every user in the system for type Year Day.

    * `:number_of_slots_daily_repeating` - A number from 0 to 255 that represents how many different schedule slots are supported for every user in the system for type Daily Repeating Day.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @type param ::
          {:number_of_slots_week_day, byte()}
          | {:number_of_slots_year_day, byte()}
          | {:number_of_slots_daily_repeating, byte()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :schedule_entry_type_supported_report,
      command_byte: 0x0A,
      command_class: ScheduleEntryLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    number_of_slots_week_day = Command.param!(command, :number_of_slots_week_day)
    number_of_slots_year_day = Command.param!(command, :number_of_slots_year_day)
    number_of_slots_daily_repeating = Command.param(command, :number_of_slots_daily_repeating)

    # Schedule Entry Lock Command Class, Version 3
    if number_of_slots_daily_repeating == nil do
      <<number_of_slots_week_day, number_of_slots_year_day>>
    else
      <<number_of_slots_week_day, number_of_slots_year_day, number_of_slots_daily_repeating>>
    end
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<number_of_slots_week_day, number_of_slots_year_day>>) do
    {:ok,
     [
       number_of_slots_week_day: number_of_slots_week_day,
       number_of_slots_year_day: number_of_slots_year_day
     ]}
  end

  # Schedule Entry Lock Command Class, Version 3
  def decode_params(
        <<number_of_slots_week_day, number_of_slots_year_day, number_of_slots_daily_repeating>>
      ) do
    {:ok,
     [
       number_of_slots_week_day: number_of_slots_week_day,
       number_of_slots_year_day: number_of_slots_year_day,
       number_of_slots_daily_repeating: number_of_slots_daily_repeating
     ]}
  end
end
