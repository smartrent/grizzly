defmodule Grizzly.MixProject do
  use Mix.Project

  @version "8.2.1"

  def project do
    [
      app: :grizzly,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      {:circular_buffer, "~> 0.4"},
      {:ctr_drbg, "~> 0.1"},
      {:dialyxir, "~> 1.4.0", only: [:test, :dev], runtime: false},
      {:mimic, "~> 1.7", only: :test},
      {:muontrap, "~> 1.0 or ~> 0.4"},
      {:ex_doc, "~> 0.21", only: :docs, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo_binary_patterns, "~> 0.2.3", only: [:dev, :test], runtime: false},
      {:sweet_xml, "~> 0.7", only: [:dev, :test]},
      {:junit_formatter, "~> 3.3", only: :test},
      {:beam_notify, "~> 1.0 or ~> 0.2.0"},
      {:telemetry, "~> 0.4.3 or ~> 1.0"},
      {:telemetry_registry, "~> 0.3"}
    ]
  end

  defp dialyzer() do
    ci_opts =
      if System.get_env("CI") do
        [plt_core_path: "_build/plts", plt_local_path: "_build/plts"]
      else
        []
      end

    [
      flags: [:unmatched_returns, :error_handling, :missing_return, :extra_return],
      plt_add_apps: [:eex, :mix, :ex_unit, :iex],
      ignore_warnings: "dialyzer_ignore_warnings.exs"
    ] ++ ci_opts
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
          Grizzly.Autocomplete,
          Grizzly.Supervisor,
          Grizzly,
          Grizzly.FirmwareUpdates,
          Grizzly.Inclusions,
          Grizzly.Indicator,
          Grizzly.Network,
          Grizzly.Node,
          Grizzly.Options,
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
        "Z/IP Gateway": [
          Grizzly.ZIPGateway,
          ~r/^Grizzly\.ZIPGateway/
        ],
        "Z-Wave": [
          Grizzly.ZWave,
          Grizzly.ZWave.Command,
          Grizzly.ZWave.CommandClass,
          Grizzly.ZWave.CRC,
          Grizzly.ZWave.DeviceClass,
          Grizzly.ZWave.DeviceClasses,
          Grizzly.ZWave.DSK,
          Grizzly.ZWave.Encoding,
          Grizzly.ZWave.IconType,
          Grizzly.ZWave.Notifications,
          Grizzly.ZWave.QRCode,
          Grizzly.ZWave.Security,
          ~r/^Grizzly\.ZWave\.SmartStart/,
          Grizzly.Inclusions.ZWaveAdapter,
          Grizzly.ZWaveFirmware,
          Grizzly.ZWaveFirmware.UpgradeSpec
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
end
