defmodule Grizzly.UnsolicitedServer.Socket do
  @moduledoc false

  use GenServer

  require Logger

  alias Grizzly.UnsolicitedServer.{SocketSupervisor, Messages}

  defmodule State do
    @moduledoc false
    defstruct listen_socket: nil
  end

  def child_spec(listen_socket) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [listen_socket]}, restart: :temporary}
  end

  def start_link(listen_socket) do
    GenServer.start_link(__MODULE__, listen_socket)
  end

  @impl true
  def init(listen_socket) do
    {:ok, %State{listen_socket: listen_socket}, {:continue, :accept}}
  end

  @impl true
  def handle_continue(:accept, %State{listen_socket: listen_socket} = state) do
    {:ok, transport_accept_sock} = :ssl.transport_accept(listen_socket)

    with {:ok, _sock} <- :ssl.handshake(transport_accept_sock) do
      # Start a new listen socket to replace this one as this one is now not
      # open for more traffic now
      {:ok, _} = SocketSupervisor.start_socket(listen_socket)
    else
      other ->
        Logger.warn(
          "grizzly: Failed to start socket. Got this on SSL handshake: #{inspect(other)}"
        )
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:ssl, {:sslsocket, {_, {_, {{ip, _}, _}}, _}, _}, data}, state) do
    :ok = Messages.broadcast(ip, data)

    {:noreply, state}
  end

  def handle_info({:ssl_closed, {:sslsocket, {_, {_, {{_ip, _}, _}}, _}, _}}, state) do
    _ = Logger.info("grizzly: unsolicated messages closed")
    {:stop, :normal, state}
  end
end
