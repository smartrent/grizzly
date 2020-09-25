defmodule Grizzly.UnsolicitedServer.Socket do
  @moduledoc false

  use GenServer

  require Logger

  alias Grizzly.Transport
  alias Grizzly.UnsolicitedServer.{SocketSupervisor, Messages}

  @spec child_spec(Transport.t()) :: map()
  def child_spec(transport) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [transport]},
      restart: :temporary
    }
  end

  @spec start_link(Transport.t()) :: GenServer.on_start()
  def start_link(listening_transport) do
    GenServer.start_link(__MODULE__, [listening_transport])
  end

  @impl GenServer
  def init([transport]) do
    {:ok, transport, {:continue, :accept}}
  end

  @impl GenServer
  def handle_continue(:accept, listening_transport) do
    with {:ok, accept_transport} <- Transport.accept(listening_transport),
         {:ok, _sock} <- Transport.handshake(accept_transport) do
      # Start a new listen socket to replace this one as this one is now not
      # open for more traffic now
      {:ok, _} = SocketSupervisor.start_socket(listening_transport)
    else
      other ->
        Logger.warn(
          "grizzly: Failed to start socket. Got this on SSL handshake: #{inspect(other)}"
        )
    end

    {:noreply, listening_transport}
  end

  @impl GenServer
  def handle_info({:ssl_closed, _}, transport) do
    {:stop, :normal, transport}
  end

  def handle_info(response, transport) do
    case Transport.parse_response(transport, response) do
      {:ok, %Transport.Response{} = transport_response} ->
        :ok = Messages.broadcast(transport_response.ip_address, transport_response.command)
        {:noreply, transport}
    end
  end
end
