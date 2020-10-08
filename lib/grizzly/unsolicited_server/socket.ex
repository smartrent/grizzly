defmodule Grizzly.UnsolicitedServer.Socket do
  @moduledoc false

  use GenServer

  require Logger

  alias Grizzly.Transport
  alias Grizzly.UnsolicitedServer.{SocketSupervisor, ResponseHandler}

  @spec child_spec(Transport.t(), [SocketSupervisor.opt()]) :: map()
  def child_spec(transport, opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [transport, opts]},
      restart: :temporary
    }
  end

  @spec start_link(Transport.t(), [SocketSupervisor.opt()]) :: GenServer.on_start()
  def start_link(listening_transport, opts \\ []) do
    GenServer.start_link(__MODULE__, [listening_transport, opts])
  end

  @impl GenServer
  def init([transport, opts]) do
    {:ok, {transport, opts}, {:continue, :accept}}
  end

  @impl GenServer
  def handle_continue(:accept, state) do
    {listening_transport, opts} = state

    with {:ok, accept_transport} <- Transport.accept(listening_transport),
         {:ok, _sock} <- Transport.handshake(accept_transport) do
      # Start a new listen socket to replace this one as this one is now not
      # open for more traffic now
      {:ok, _} = SocketSupervisor.start_socket(listening_transport, opts)
    else
      other ->
        Logger.warn(
          "grizzly: Failed to start socket. Got this on SSL handshake: #{inspect(other)}"
        )
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:ssl_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info(response, state) do
    {transport, opts} = state

    case Transport.parse_response(transport, response) do
      {:ok, %Transport.Response{} = transport_response} ->
        ResponseHandler.handle_response(transport, transport_response, opts)
        {:noreply, state}
    end
  end
end
