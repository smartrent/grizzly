defmodule Grizzly.UnsolicitedServer do
  @moduledoc false
  use GenServer

  require Logger

  alias Grizzly.{Options, Transport}
  alias Grizzly.UnsolicitedServer.{SocketSupervisor, ResponseHandler}

  defmodule State do
    @moduledoc false
    defstruct transport: nil
  end

  @doc """
  Start the unsolicited server
  """
  @spec start_link(Options.t()) :: GenServer.on_start()
  def start_link(grizzly_opts) do
    GenServer.start_link(__MODULE__, grizzly_opts, name: __MODULE__)
  end

  @impl GenServer
  def init(%Options{} = grizzly_opts) do
    {ip, port} = grizzly_opts.unsolicited_destination

    transport =
      Transport.new(grizzly_opts.transport, %{
        ip_address: ip,
        port: port
      })

    {:ok, %State{transport: transport}, {:continue, :listen}}
  end

  @impl GenServer
  def handle_continue(:listen, state) do
    %State{transport: transport} = state

    case listen(transport) do
      {:ok, listening_transport, listen_opts} ->
        maybe_start_accept_sockets(listening_transport, listen_opts)
        {:noreply, %State{state | transport: listening_transport}}

      _error ->
        # wait 2 seconds to try again
        _ = Logger.warn("[Grizzly]: Unsolicited server unable to listen")
        :timer.sleep(2000)
        {:noreply, state, {:continue, :listen}}
    end
  end

  @impl GenServer
  def handle_info(message, state) do
    %State{transport: transport} = state

    case Transport.parse_response(transport, message) do
      {:ok, transport_response} ->
        ResponseHandler.handle_response(transport, transport_response)
        {:noreply, state}
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
        Enum.each(1..10, fn _ ->
          SocketSupervisor.start_socket(listening_transport)
        end)

      :none ->
        :ok
    end
  end
end
