# Start the mock Z/IP Gateway server
{:ok, _pid} =
  ThousandIsland.start_link(
    handler_module: GrizzlyTest.Server.Handler,
    handler_options: %{node_id: nil},
    port: 5000,
    transport_module: Grizzly.UnsolicitedServer.DTLSTransport,
    transport_options: [ifaddr: {127, 0, 0, 1}],
    num_acceptors: 10
  )

Mimic.copy(Grizzly)
Mimic.copy(Grizzly.Connections.AsyncConnection)
Mimic.copy(MockStatusReporter)
Mimic.copy(MockZWaveResetter)
Mimic.copy(MuonTrap)

Grizzly.Supervisor.start_link(GrizzlyTest.Utils.default_options_args())

extra_formatters = if(System.get_env("CI"), do: [JUnitFormatter], else: [])

config = [
  capture_log: true,
  exclude: [
    inclusion: true,
    integration: true,
    firmware_update: true
  ],
  formatters: ExUnit.configuration()[:formatters] ++ extra_formatters
]

ExUnit.configure(config)
ExUnit.start()
