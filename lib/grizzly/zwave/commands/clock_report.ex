defmodule Grizzly.ZWave.Commands.ClockReport do
  @moduledoc """
  This command reports on the current time in a supporting node

  Params:

    * `:weekday` - the day of the week, one of :sunday, :monday, etc. (required)

    * `:hour` - 0..23 (required)

    * `:minute` - 0..59 (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Clock

  @type param :: {:weekday, Clock.weekday()} | {:hour, 0..23} | {:minute, 0..59}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :clock_report,
      command_byte: 0x06,
      command_class: Clock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    encoded_weekday = Command.param!(command, :weekday) |> Clock.encode_weekday()
    hour = Command.param!(command, :hour)
    minute = Command.param!(command, :minute)
    <<encoded_weekday::3, hour::5, minute>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<encoded_weekday::3, hour::5, minute>>) do
    with {:ok, weekday} <- Clock.decode_weekday(encoded_weekday) do
      if hour in 0..23 do
        if minute in 0..59 do
          {:ok, [weekday: weekday, hour: hour, minute: minute]}
        else
          {:error, %DecodeError{param: :minute, value: minute, command: :clock_set}}
        end
      else
        {:error, %DecodeError{param: :hour, value: hour, command: :clock_set}}
      end
    else
      {:error, decode_error} ->
        {:error, %DecodeError{decode_error | command: :clock_set}}
    end
  end
end
