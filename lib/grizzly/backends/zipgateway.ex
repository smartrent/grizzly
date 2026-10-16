defmodule Grizzly.Backends.Zipgateway do
  @moduledoc false
  alias Grizzly.Connections.AsyncConnection
  alias Grizzly.Connections.BinaryConnection
  alias Grizzly.Connections.SyncConnection
  alias Grizzly.ZIPGateway.Database
  alias Grizzly.ZIPGateway.LogMonitor
  alias Grizzly.ZIPGateway.ReadyChecker
  alias Grizzly.ZIPGateway.Supervisor, as: GatewaySupervisor

  def children(options) do
    {ip, port} = options.unsolicited_destination

    [
      if(options.run_zipgateway, do: {GatewaySupervisor, options}),
      {ThousandIsland,
       [
         port: port,
         num_acceptors: 10,
         handler_module: Grizzly.UnsolicitedServer.ConnectionHandler,
         handler_options: [inclusion_handler: options.inclusion_handler],
         transport_module: Grizzly.UnsolicitedServer.DTLSTransport,
         transport_options: [ifaddr: ip],
         supervisor_options: [name: Grizzly.UnsolicitedServer]
       ]}
    ]
    |> Enum.reject(&is_nil/1)
  end

  def post_children(_), do: [ReadyChecker]
  def controller_id(), do: 1
  def ready?(), do: ReadyChecker.ready?()
  def listening_mode(node), do: Database.listening_mode(node)
  def home_id(), do: inspection(&LogMonitor.home_id/1)
  def network_keys(), do: inspection(&LogMonitor.network_keys/1)
  def zniffer_network_keys(), do: inspection(&LogMonitor.zniffer_network_keys/1)

  def connection_spec(node, opts) do
    opts = Keyword.put_new(opts, :owner, self())

    spec =
      case Keyword.get(opts, :mode, :sync) do
        :async -> AsyncConnection.child_spec(node, opts)
        :sync -> SyncConnection.child_spec(node, opts)
        :binary -> BinaryConnection.child_spec(node, opts)
      end

    {:ok, spec}
  end

  def zipgateway_operation(:start_zipgateway), do: GatewaySupervisor.start_zipgateway()
  def zipgateway_operation(:restart_zipgateway), do: GatewaySupervisor.restart_zipgateway()
  def zipgateway_operation(:stop_zipgateway), do: GatewaySupervisor.stop_zipgateway()

  def zipgateway_operation({:send_binary, node, bytes}),
    do: BinaryConnection.send_binary(node, bytes)

  defp inspection(fun) do
    case GenServer.whereis(LogMonitor) do
      nil -> nil
      pid -> fun.(pid)
    end
  end
end
