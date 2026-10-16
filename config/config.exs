import Config

# This value is read by Application.compile_env, never by a runtime selector.
backend =
  case System.get_env("GRIZZLY_BACKEND", "zipgateway") do
    "zipgateway" -> :zipgateway
    "zwrap" -> :zwrap
    other -> raise "Invalid GRIZZLY_BACKEND: #{inspect(other)}"
  end

config :grizzly, :backend, backend

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
