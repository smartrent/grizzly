defmodule Grizzly.UnsolicitedServer.Socket do
  @moduledoc false

  use GenServer

  require Logger
  alias Grizzly.{Notifications, Packet, Node}
  alias Grizzly.UnsolicitedServer.Socket.Supervisor, as: SocketSupervisor

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

  @spec prepare_message(Packet.t(), Node.node_id()) :: map
  def prepare_message(%Packet{} = packet, node_id) do
    # TODO: clean up after refactoring to reports
    if Map.has_key?(packet.body, :value) do
      %{node_id: node_id, command_class: packet.body.command_class, value: packet.body.value}
    else
      prepared_body = Map.drop(packet.body, [:command_class])
      %{node_id: node_id, command_class: packet.body.command_class, value: prepared_body}
    end
  end

  @impl true
  def init(listen_socket) do
    send(self(), :accept)
    {:ok, %State{listen_socket: listen_socket}}
  end

  @impl true
  def handle_info(:accept, %State{listen_socket: listen_socket} = state) do
    {:ok, transport_accept_sock} = :ssl.transport_accept(listen_socket)

    with {:ok, _sock} <- :ssl.handshake(transport_accept_sock) do
      {:ok, _} = SocketSupervisor.start_socket(listen_socket)
    else
      other -> Logger.warn("Failed to start socket. Got this on SSL handshake: #{inspect(other)}")
    end

    {:noreply, state}
  end

  def handle_info({:ssl, {:sslsocket, {_, {_, {{ip, _}, _}}, _}, _}, data}, %State{} = state) do
    node_id = ip |> get_node_id()

    parsed_data =
      data
      |> :binary.list_to_bin()
      |> Packet.decode()

    _ = Logger.debug("[GRIZZLY]: unsolicited message received: #{inspect(parsed_data)}")
    Notifications.broadcast(:unsolicited_message, prepare_message(parsed_data, node_id))
    {:noreply, state}
  end

  def handle_info({:ssl_closed, {:sslsocket, {_, {_, {{_ip, _}, _}}, _}, _}}, state) do
    _ = Logger.info("[GRIZZLY]: unsolicated messages closed")
    {:stop, :normal, state}
  end

  defp get_node_id(ip) do
    node_id_index = tuple_size(ip) - 1
    elem(ip, node_id_index)
  end
end
