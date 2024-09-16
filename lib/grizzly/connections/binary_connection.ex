defmodule Grizzly.Connections.BinaryConnection do
  @moduledoc false

  # A special connection that only handles send and receiving binary data
  # This connection works when using `Grizzly.send_binary/2` by using the
  # the calling process as part of the GenServer name to ensure that many
  # calling sites can send these commands to the same node id with getting
  # each other's messages.

  # As of right now this connection won't use keep alive and will close it self
  # after 25 seconds of inactivity. For the known use cases for this connection
  # the behavior is ideal. Namely debugging and quick one off commands like when
  # another device asks us something about our device.

  use GenServer
  require Logger

  alias Grizzly.{Connections, Options, Transport, ZIPGateway, ZWave}

  defmodule State do
    @moduledoc false

    @enforce_keys [:transport, :owner, :node_id]
    defstruct transport: nil, owner: nil, node_id: nil
  end

  def child_spec(node_id, opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [node_id, opts]}, restart: :transient}
  end

  @doc """
  Start the BinaryConnection
  """
  @spec start_link(Options.t(), ZWave.node_id(), keyword()) :: GenServer.on_start()
  def start_link(grizzly_options, node_id, opts) do
    owner = Keyword.fetch!(opts, :owner)
    name = Connections.make_name({:binary, node_id, owner})
    GenServer.start_link(__MODULE__, [grizzly_options, node_id, owner], name: name)
  end

  @doc """
  Send a binary packet to the Z-Wave node
  """
  @spec send_binary(ZWave.node_id(), binary()) :: :ok
  def send_binary(node_id, binary) do
    name = Connections.make_name({:binary, node_id, self()})
    GenServer.call(name, {:send_binary, binary})
  end

  @impl GenServer
  def init([grizzly_options, node_id, owner]) do
    host = ZIPGateway.host_for_node(node_id, grizzly_options)
    transport_impl = grizzly_options.transport

    transport_opts = [
      ip_address: host,
      port: grizzly_options.zipgateway_port,
      node_id: node_id
    ]

    case Transport.open(transport_impl, transport_opts) do
      {:ok, transport} ->
        {:ok,
         %State{
           transport: transport,
           owner: owner,
           node_id: node_id
         }}

      {:error, :timeout} ->
        {:stop, :timeout}
    end
  end

  @impl GenServer
  def handle_call({:send_binary, binary}, _from, state) do
    %State{transport: transport} = state

    Transport.send(transport, binary)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(data, state) do
    %State{transport: transport, owner: owner, node_id: node_id} = state

    case Transport.parse_response(transport, data, raw: true) do
      {:ok, :connection_closed} ->
        Logger.debug("[Grizzly] connection to node #{inspect(node_id)} closed")
        {:stop, :normal, state}

      {:ok, binary} ->
        send(owner, {:grizzly, :binary_response, binary})
        {:noreply, state}
    end
  end
end
