defmodule Grizzly.MixProject do
  use Mix.Project

  @version "4.0.1"

  def project do
    [
      app: :grizzly,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      description: description(),
      package: package(),
      docs: docs(),
      preferred_cli_env: [docs: :docs, "hex.publish": :docs],
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
      {:dialyxir, "~> 1.1.0", only: [:test, :dev], runtime: false},
      {:muontrap, "~> 1.0 or ~> 0.4"},
      {:ex_doc, "~> 0.21", only: :docs, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:beam_notify, "~> 1.0 or ~> 0.2.0"}
    ]
  end

  defp dialyzer() do
    [
      flags: [:unmatched_returns, :error_handling],
      plt_add_apps: [:eex, :mix],
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
          Grizzly.Inclusions,
          Grizzly.Indicator,
          Grizzly.Network,
          Grizzly.Node,
          Grizzly.Trace,
          Grizzly.Trace.Record,
          Grizzly.StatusReporter,
          Grizzly.StatusReporter.Console,
          Grizzly.Report
        ],
        "Grizzly Command Modules": [
          Grizzly.SwitchBinary
        ],
        "Virtual Devices": [
          Grizzly.VirtualDevices,
          Grizzly.VirtualDevices.Device,
          Grizzly.VirtualDevices.Thermostat
        ],
        ZWave: [
          Grizzly.ZWave,
          Grizzly.ZWave.CRC,
          Grizzly.ZWave.DeviceClass,
          Grizzly.ZWave.DeviceClasses,
          Grizzly.ZWave.DSK,
          Grizzly.ZWave.IconType,
          Grizzly.ZWave.Notifications,
          Grizzly.ZWave.QRCode,
          Grizzly.ZWave.Security
        ],
        Transports: [
          Grizzly.Transport,
          Grizzly.Transport.Response,
          Grizzly.Transports.DTLS,
          Grizzly.Transports.UDP
        ]
      ]
    ]
  end

  defp aliases() do
    [
      test: ["test --exclude integration --exclude inclusion --exclude firmware_update"]
    ]
  end
end
