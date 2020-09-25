defmodule Grizzly.UnsolicitedServer do
  @moduledoc false
  use GenServer

  require Logger

  alias Grizzly.{Options, Transport, ZIPGateway}
  alias Grizzly.UnsolicitedServer.SocketSupervisor

  @spec start_link(Options.t()) :: GenServer.on_start()
  def start_link(grizzly_opts) do
    GenServer.start_link(__MODULE__, grizzly_opts, name: __MODULE__)
  end

  @impl true
  def init(grizzly_opts) do
    transport =
      Transport.new(grizzly_opts.transport, %{
        ip_address: ZIPGateway.unsolicited_server_ip(),
        port: 41230
      })

    {:ok, transport, {:continue, :listen}}
  end

  @impl true
  def handle_continue(:listen, transport) do
    case listen(transport) do
      {:ok, listening_transport, listen_opts} ->
        maybe_start_accept_sockets(listening_transport, listen_opts)
        {:noreply, transport}

      _error ->
        # wait 2 seconds to try again
        _ = Logger.warn("[Grizzly]: Unsolicited server unable to listen")
        :timer.sleep(2000)
        {:noreply, transport, {:continue, :listen}}
    end
  end

  def listen(transport) do
    try do
      Transport.listen(transport)
    rescue
      error -> error
    end
  end

  def maybe_start_accept_sockets(listening_transport, listen_opts) do
    case Keyword.get(listen_opts, :strategy) do
      :accept ->
        Enum.each(1..10, fn _ -> SocketSupervisor.start_socket(listening_transport) end)

      :none ->
        :ok
    end
  end
end
