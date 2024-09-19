defmodule Grizzly.ZWave.Commands.DateReport do
  @moduledoc """
  This command is used to advertise the current date adjusted according to the local time zone and
  Daylight Saving Time.

  Params:

    * `:year` - the year (required)

    * `:month` - the month (required)

    * `:day` - the day (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Time

  @type param :: {:year, integer()} | {:month, 1..12} | {:day, 1..31}
  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :date_report,
      command_byte: 0x04,
      command_class: Time,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    year = Command.param!(command, :year)
    month = Command.param!(command, :month)
    day = Command.param!(command, :day)
    <<year::16, month, day>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<year::16, month, day>>) do
    {:ok, [year: year, month: month, day: day]}
  end
end
