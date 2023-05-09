defmodule Grizzly.ZIPGateway.Waiter do
  @moduledoc """
  Waits for Z/IP Gateway to be ready before returning from its `c:GenServer.init/1` callback.

  Put this in your supervision tree after `Grizzly.Supervisor` to block the rest of
  your application from starting until Z/IP Gateway is ready. Please note that this
  is not compatible with the `:one_for_all` strategy.
  """

  use GenServer, restart: :transient

  require Logger

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    GenServer.start_link(__MODULE__, [], timeout: timeout)
  end

  def init(_) do
    :ok = try_connect()
    Logger.info("[Grizzly.ZIPGateway.Waiter] Z/IP Gateway is ready")
    :ignore
  end

  defp try_connect() do
    case Grizzly.ping(:gateway, transmission_stats: false) do
      {:ok, %Grizzly.Report{status: :complete, type: :ack_response}} ->
        :ok

      _ ->
        # give a little breathing space
        :timer.sleep(500)

        # try again
        try_connect()
    end
  end
end
