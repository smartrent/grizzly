# Start the mock Z/IP Gateway server
Registry.start_link(keys: :unique, name: GrizzlyTest.Server.ConnectionRegistry)

{:ok, test_server} =
  ThousandIsland.start_link(
    handler_module: GrizzlyTest.Server.Handler,
    handler_options: %{node_id: nil},
    port: 0,
    transport_module: Grizzly.UnsolicitedServer.DTLSTransport,
    transport_options: [ifaddr: {127, 0, 0, 1}],
    num_acceptors: 10
  )

{:ok, {_ip, port}} = ThousandIsland.listener_info(test_server)
:persistent_term.put(:zipgateway_port, port)

Mimic.copy(Grizzly)
Mimic.copy(Grizzly.Connections.AsyncConnection)
Mimic.copy(MockZWaveResetter)
Mimic.copy(MuonTrap)

Grizzly.Supervisor.start_link(GrizzlyTest.Utils.default_options_args())

extra_formatters = if(System.get_env("CI"), do: [JUnitFormatter], else: [])

config = [
  capture_log: true,
  formatters: ExUnit.configuration()[:formatters] ++ extra_formatters,
  exclude: [hardware: true]
]

ExUnit.configure(config)
ExUnit.start()
