{:ok, _pid} = GrizzlyTest.Server.start(5000)

Grizzly.Supervisor.start_link(GrizzlyTest.Utils.default_options_args())

ExUnit.start()
