defmodule Grizzly.CommandHandlers.AckResponse do
  @moduledoc """
  This handler is useful for most set commands that only needs to be
  acknowledged
  """
  @behaviour Grizzly.CommandHandler

  @impl Grizzly.CommandHandler
  def init(_) do
    {:ok, nil}
  end

  @impl Grizzly.CommandHandler
  def handle_ack(_), do: {:complete, :ok}

  @impl Grizzly.CommandHandler
  def handle_command(_, state), do: {:continue, state}
end
