{:ok, _pid} = GrizzlyTest.Server.start(5000)

Grizzly.Supervisor.start_link(GrizzlyTest.Utils.default_options_args())

ExUnit.configure(capture_log: true)
ExUnit.start()
