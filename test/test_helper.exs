{:ok, _pid} = GrizzlyTest.Server.start(5000)

Grizzly.Supervisor.start_link(GrizzlyTest.Utils.default_options_args())

config =
  case System.get_env("CI") do
    nil -> []
    _ -> [formatters: [ExUnit.CLIFormatter, JUnitFormatter]]
  end

Logger.configure(level: :debug)

ExUnit.configure(Keyword.merge(config, capture_log: true))
ExUnit.start()
