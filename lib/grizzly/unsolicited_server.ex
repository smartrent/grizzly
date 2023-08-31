defmodule Grizzly.UnsolicitedServer do
  @moduledoc false
  use GenServer

  require Logger

  alias Grizzly.{Options, Transport}
  alias Grizzly.UnsolicitedServer.SocketSupervisor

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

    {:ok, transport, {:continue, :listen}}
  end

  @impl GenServer
  def handle_continue(:listen, transport) do
    case listen(transport) do
      {:ok, listening_transport, listen_opts} ->
        maybe_start_accept_sockets(listening_transport, listen_opts)
        {:noreply, listening_transport}

      _error ->
        # wait 2 seconds to try again
        Logger.warning("[Grizzly]: Unsolicited server unable to listen")
        :timer.sleep(2000)
        {:noreply, transport, {:continue, :listen}}
    end
  end

  defp listen(transport) do
    Transport.listen(transport)
  rescue
    error -> error
  end

  defp maybe_start_accept_sockets(listening_transport, listen_opts) do
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
