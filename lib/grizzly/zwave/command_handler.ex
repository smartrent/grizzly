defmodule Grizzly.ZWave.CommandHandler do
  alias Grizzly.ZWave.Command

  @type handle_response :: {:complete, response :: any()} | {:continue, state :: any()}

  @callback init(any()) :: {:ok, state :: any()}

  @callback handle_ack(state :: any()) :: handle_response()

  @callback handle_command(Command.t(), state :: any()) :: handle_response()

  @optional_callbacks handle_command: 2
end
