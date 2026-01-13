defmodule Grizzly.ZWave.Commands.ClockSetReport do
  @moduledoc """
  This command is used to set the current time in a supporting node

  Params:

    * `:weekday` - the day of the week, one of :sunday, :monday, etc. (required)

    * `:hour` - 0..23 (required)

    * `:minute` - 0..59 (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Clock
  alias Grizzly.ZWave.DecodeError

  @type param :: {:weekday, Clock.weekday()} | {:hour, 0..23} | {:minute, 0..59}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    encoded_weekday = Command.param!(command, :weekday) |> Clock.encode_weekday()
    hour = Command.param!(command, :hour)
    minute = Command.param!(command, :minute)
    <<encoded_weekday::3, hour::5, minute>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<encoded_weekday::3, hour::5, minute>>) do
    with {:ok, weekday} <- Clock.decode_weekday(encoded_weekday) do
      if hour in 0..23 do
        if minute in 0..59 do
          {:ok, [weekday: weekday, hour: hour, minute: minute]}
        else
          {:error, %DecodeError{param: :minute, value: minute}}
        end
      else
        {:error, %DecodeError{param: :hour, value: hour}}
      end
    end
  end
end
