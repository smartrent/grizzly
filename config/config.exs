import Config

config :logger, level: :info

if config_env() == :test do
  config :junit_formatter, report_dir: File.cwd!()
end
