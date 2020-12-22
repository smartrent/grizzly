defmodule Grizzly.ZIPGateway.ReadyChecker do
  @moduledoc false

  # A process that runs at the start of the Grizzly supervisor to when the
  # zipgateway is up and running.

  use GenServer, restart: :transient

  alias Grizzly.Connection

  @type on_ready() :: mfa()

  @spec start_link(on_ready()) :: GenServer.on_start()
  def start_link(on_ready) do
    GenServer.start_link(__MODULE__, on_ready, name: __MODULE__)
  end

  @impl GenServer
  def init(on_ready) do
    {:ok, on_ready, {:continue, :try_connect}}
  end

  @impl GenServer
  def handle_continue(:try_connect, on_ready) do
    case Connection.open(:gateway) do
      {:ok, _} ->
        {m, f, a} = on_ready
        :ok = apply(m, f, a)
        {:stop, :normal, on_ready}

      {:error, _reason} ->
        # give a little breathing space
        :timer.sleep(500)

        # try again
        {:noreply, on_ready, {:continue, :try_connect}}
    end
  end
end
