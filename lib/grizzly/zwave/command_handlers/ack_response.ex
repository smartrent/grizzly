defmodule Grizzly.ZWave.CommandHandlers.AckResponse do
  @moduledoc """
  This handler is useful for most set commands that only needs to be
  acknowledged
  """
  @behaviour Grizzly.ZWave.CommandHandler

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_ack(_), do: {:complete, :ok}

  @impl true
  def handle_command(_, state), do: {:continue, state}
end
