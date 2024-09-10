{:ok, _pid} = GrizzlyTest.Server.start(5000)

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
