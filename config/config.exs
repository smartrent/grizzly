import Config

config :logger, level: :debug

if config_env() == :test do
  config :junit_formatter, report_dir: File.cwd!()
end
