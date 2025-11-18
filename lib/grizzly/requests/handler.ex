defmodule Grizzly.Requests.Handler do
  @moduledoc """
  Behaviour for how commands should handle incoming Z-Wave messages
  """

  alias Grizzly.ZWave.Command

  @type handle_response :: {:complete, response :: any()} | {:continue, state :: any()}

  @callback init(original_command :: Command.t(), init_state :: any()) :: {:ok, state :: any()}

  @callback handle_ack(state :: any()) :: handle_response()

  @callback handle_command(incoming_command :: Command.t(), state :: any()) :: handle_response()

  @optional_callbacks handle_command: 2
end
