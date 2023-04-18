defmodule Grizzly.MixProject do
  use Mix.Project

  @version "6.4.0"

  def project do
    [
      app: :grizzly,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      description: description(),
      package: package(),
      docs: docs(),
      preferred_cli_env: [docs: :docs, "hex.publish": :docs, dialyzer: :test],
      xref: [exclude: EEx]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :asn1, :public_key, :ssl]
    ]
  end

  def elixirc_paths(:test), do: ["test/support", "lib"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:cerlc, "~> 0.2.0"},
      {:dialyxir, "~> 1.3.0", only: [:test, :dev], runtime: false},
      {:muontrap, "~> 1.0 or ~> 0.4"},
      {:ex_doc, "~> 0.21", only: :docs, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:junit_formatter, "~> 3.3", only: :test},
      {:beam_notify, "~> 1.0 or ~> 0.2.0"}
    ]
  end

  defp dialyzer() do
    [
      flags: [:unmatched_returns, :error_handling, :missing_return, :extra_return],
      plt_add_apps: [:eex, :mix, :ex_unit],
      ignore_warnings: "dialyzer_ignore_warnings.exs"
    ]
  end

  defp description do
    "Elixir Z-Wave library"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/smartrent/grizzly"}
    ]
  end

  defp docs() do
    [
      extras: ["README.md", "CHANGELOG.md", "docs/cookbook.md"],
      main: "readme",
      logo: "./assets/grizzly-icon-yellow.png",
      source_ref: "v#{@version}",
      source_url: "https://github.com/smartrent/grizzly",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_modules: [
        Core: [
          Grizzly.Supervisor,
          Grizzly,
          Grizzly.FirmwareUpdates,
          Grizzly.Inclusions,
          Grizzly.Indicator,
          Grizzly.Network,
          Grizzly.Node,
          Grizzly.Trace,
          Grizzly.Trace.Record,
          Grizzly.StatusReporter,
          Grizzly.StatusReporter.Console,
          Grizzly.Report,
          ~r/^Grizzly\.CommandHandlers/
        ],
        Behaviours: [
          Grizzly.CommandHandler,
          Grizzly.FirmwareUpdateHandler,
          Grizzly.InclusionHandler,
          Grizzly.Inclusions.NetworkAdapter
        ],
        "Grizzly Command Modules": [
          Grizzly.SwitchBinary
        ],
        "Virtual Devices": [
          Grizzly.VirtualDevices,
          Grizzly.VirtualDevices.Device,
          Grizzly.VirtualDevices.TemperatureSensor,
          Grizzly.VirtualDevices.Thermostat
        ],
        "Z-Wave": [
          Grizzly.ZWave,
          Grizzly.ZWave.Command,
          Grizzly.ZWave.CommandClass,
          Grizzly.ZWave.CRC,
          Grizzly.ZWave.DeviceClass,
          Grizzly.ZWave.DeviceClasses,
          Grizzly.ZWave.DSK,
          Grizzly.ZWave.IconType,
          Grizzly.ZWave.Notifications,
          Grizzly.ZWave.QRCode,
          Grizzly.ZWave.Security,
          ~r/^Grizzly\.ZWave\.SmartStart/,
          Grizzly.Inclusions.ZWaveAdapter
        ],
        Transports: [
          Grizzly.Transport,
          Grizzly.Transport.Response,
          Grizzly.Transports.DTLS,
          Grizzly.Transports.UDP
        ],
        "Z-Wave Protocol": [
          ~r/^Grizzly\.ZWave\.CommandClasses/,
          ~r/^Grizzly\.ZWave\.Commands/
        ]
      ],
      nest_modules_by_prefix: [
        Grizzly.CommandHandlers,
        Grizzly.ZWave.CommandClasses,
        Grizzly.ZWave.Commands
      ]
    ]
  end

  defp aliases() do
    [
      test: ["test --exclude integration --exclude inclusion --exclude firmware_update"]
    ]
  end
end
