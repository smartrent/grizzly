defmodule Grizzly.ZIPGateway.ReadyChecker do
  @moduledoc false

  # A process that runs at the start of the Grizzly supervisor to when the
  # zipgateway is up and running.

  use GenServer, restart: :transient

  alias Grizzly.Connection

  @type init_arg() :: {:status_reporter, module()}

  @spec start_link([init_arg()]) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    {:ok, %{reporter: args[:status_reporter]}, {:continue, :try_connect}}
  end

  @impl GenServer
  def handle_continue(:try_connect, state) do
    case Connection.open(:gateway) do
      {:ok, _} ->
        state.reporter.ready()
        {:stop, :normal, state}

      {:error, _reason} ->
        # give a little breathing space
        :timer.sleep(500)

        # try again
        {:noreply, state, {:continue, :try_connect}}
    end
  end
end
