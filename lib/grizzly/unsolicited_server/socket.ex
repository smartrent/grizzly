defmodule Grizzly.UnsolicitedServer.Socket do
  @moduledoc false

  use GenServer

  require Logger

  alias Grizzly.{SeqNumber, Transport, ZWave}
  alias Grizzly.ZWave.Commands.ZIPPacket
  alias Grizzly.UnsolicitedServer.{Messages, SocketSupervisor, ResponseHandler}

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
    GenServer.start_link(__MODULE__, listening_transport)
  end

  @impl GenServer
  def init(transport) do
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
    {:ok, transport_response} = Transport.parse_response(transport, response)

    case ResponseHandler.handle_response(transport_response) do
      [] ->
        :ok

      actions ->
        Enum.each(actions, &run_response_action(transport, transport_response, &1))
    end

    {:noreply, transport}
  end

  defp run_response_action(transport, response, {:send, command}) do
    %Transport.Response{ip_address: ip_address, port: port} = response
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(), flag: nil)

    binary = ZWave.to_binary(zip_packet)

    Transport.send(transport, binary, to: {ip_address, port})
  end

  defp run_response_action(_transport, response, {:notify, command}) do
    :ok = Messages.broadcast(response.ip_address, command)
  end
end
