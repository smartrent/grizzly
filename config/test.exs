use Mix.Config

config :grizzly,
  run_zipgateway_bin: false

config :grizzly, Grizzly.Controller,
  ip: {0, 0, 0, 0},
  port: 5000,
  client: Grizzly.Test.Client

config :logger, level: :error
