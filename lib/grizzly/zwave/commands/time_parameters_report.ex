defmodule Grizzly.ZWave.Commands.TimeParametersReport do
  @moduledoc """
  This command is used to advertise date and time.

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
  alias Grizzly.ZWave.CommandClasses.TimeParameters

  @type param ::
          {:year, non_neg_integer}
          | {:month, 1..12}
          | {:day, 1..31}
          | {:hour_utc, 0..23}
          | {:minute_utc, 0..59}
          | {:second_utc, 0..59}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :time_parameters_report,
      command_byte: 0x03,
      command_class: TimeParameters,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    year = Command.param!(command, :year)
    month = Command.param!(command, :month)
    day = Command.param!(command, :day)
    hour_utc = Command.param!(command, :hour_utc)
    minute_utc = Command.param!(command, :minute_utc)
    second_utc = Command.param!(command, :second_utc)
    <<year::size(16)-integer-unsigned, month, day, hour_utc, minute_utc, second_utc>>
  end

  @impl true
  def decode_params(
        <<year::size(16)-integer-unsigned, month, day, hour_utc, minute_utc, second_utc>>
      ) do
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
