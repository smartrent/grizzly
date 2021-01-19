defmodule Grizzly.Indicator do
  @moduledoc """
  Indicator handling for Grizzly when an indicator event is triggered

  See `Grizzly.Supervisor` for configuring the dispatcher that Grizzly should
  use during runtime.
  """

  require Logger

  @type event() :: :on | :off

  @type dispatcher() :: (event() -> :ok)

  @doc """
  Handles an event from `BEAMNotify`
  """
  @spec handle_event([String.t()], %{String.t() => String.t()}, dispatcher()) :: :ok
  def handle_event(event, _env, dispatcher) do
    case Integer.parse(hd(event)) do
      {0, _} -> dispatcher.(:off)
      {v, _} when v > 1 -> dispatcher.(:on)
      :error -> Logger.debug("Received unexpected indicator event: #{inspect(event)}")
    end
  end
end
