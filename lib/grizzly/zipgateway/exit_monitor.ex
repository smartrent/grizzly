defmodule Grizzly.ZIPGateway.ExitMonitor do
  @moduledoc false

  use GenServer

  def start_link(_ \\ []) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, []}
  end

  @impl GenServer
  def terminate(_reason, _state) do
    Grizzly.Connections.close_all()

    :ok
  end
end
