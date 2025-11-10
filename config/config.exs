import Config

config :logger, level: :debug

if config_env() == :test do
  config :junit_formatter,
    report_dir: File.cwd!(),
    include_filename?: true

  config :grizzly,
    unsolicited_server_health_check_interval: 1000,
    dtls_handshake_timeout: 100

  config :grizzly, Grizzly.Storage.Populate, disabled: true

  if File.exists?("config/test.local.exs") do
    import_config "test.local.exs"
  end
end
