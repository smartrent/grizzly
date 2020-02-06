use Mix.Config

config :grizzly,
  transport: GrizzlyTest.Transport.UDP,
  zip_gateway: %{
    host: {0, 0, 0, 0}
  },
  runtime: [
    auto_start: false,
    run_zipgatway_bin: false
  ]

config :logger, level: :error
