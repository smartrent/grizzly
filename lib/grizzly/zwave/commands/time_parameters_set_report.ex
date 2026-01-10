defmodule Grizzly.ZWave.Commands.TimeParametersSetReport do
  @moduledoc """
  This command is used to set current date and time in Universal Time (UTC).

  Params:

    * `:year` - the year (required)

    * `:month` - the month (required - 1..12)

    * `:day` - the day (required - 1..31)

    * `:hour_utc` - the hour in UTC time (required - 0..23)

    * `:minute_utc` - the minute in UTC time (required - 0..59)

    * `:second_utc` - the second in UTC time (required - 0..59)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param ::
          {:year, non_neg_integer}
          | {:month, 1..12}
          | {:day, 1..31}
          | {:hour_utc, 0..23}
          | {:minute_utc, 0..59}
          | {:second_utc, 0..59}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    year = Command.param!(command, :year)
    month = Command.param!(command, :month)
    day = Command.param!(command, :day)
    hour_utc = Command.param!(command, :hour_utc)
    minute_utc = Command.param!(command, :minute_utc)
    second_utc = Command.param!(command, :second_utc)
    <<year::16, month, day, hour_utc, minute_utc, second_utc>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<year::16, month, day, hour_utc, minute_utc, second_utc>>) do
    {:ok,
     [
       year: year,
       month: month,
       day: day,
       hour_utc: hour_utc,
       minute_utc: minute_utc,
       second_utc: second_utc
     ]}
  end
end
