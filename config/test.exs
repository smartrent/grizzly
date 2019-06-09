use Mix.Config

config :grizzly,
  run_zipgateway: false

config :grizzly, ZipGateway.Controller,
  ip: {0, 0, 0, 0},
  port: 5000,
  client: ZipGateway.Test.Client

config :logger, level: :error
