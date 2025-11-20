defmodule Grizzly.MixProject do
  use Mix.Project

  @version "8.15.3"

  def project do
    [
      app: :grizzly,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      description: description(),
      package: package(),
      docs: docs(),
      test_coverage: [
        ignore_modules: [~r/^GrizzlyTest/, ~r/^Mock/, ~r/^Mix/]
      ],
      xref: [exclude: EEx]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :asn1, :public_key, :ssl, :sasl]
    ]
  end

  def cli do
    [
      preferred_envs: ["hex.publish": :docs, docs: :docs, dialyzer: :test]
    ]
  end

  def elixirc_paths(:test), do: ["test/support", "lib"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:alarmist, "~> 0.4", only: [:test]},
      {:beam_notify, "~> 1.0 or ~> 0.2.0"},
      {:cerlc, "~> 0.2"},
      {:circuits_uart, "~> 1.0"},
      {:circular_buffer, "~> 1.0 or ~> 0.4.2"},
      {:credo_binary_patterns, "~> 0.2.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ctr_drbg, "~> 0.1"},
      {:dialyxir, "~> 1.4.0", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.21", only: [:docs, :test], runtime: false},
      {:exmodem, "~> 0.1"},
      {:exqlite, "~> 0.33"},
      {:junit_formatter, "~> 3.3", only: :test},
      {:mimic, "~> 2.0", only: [:dev, :test]},
      {:muontrap, "~> 1.6"},
      {:nimble_options, "~> 1.0"},
      {:property_table, "~> 0.3"},
      {:sweet_xml, "~> 0.7", only: [:dev, :test]},
      {:telemetry_registry, "~> 0.3"},
      {:telemetry, "~> 0.4.3 or ~> 1.0"},
      {:thousand_island, "~> 1.3"}
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
      plt_add_apps: [:eex, :mix, :ex_unit, :iex]
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
      favicon: "./assets/grizzly-icon-yellow.png",
      source_ref: "v#{@version}",
      source_url: "https://github.com/smartrent/grizzly",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_modules: [
        Core: [
          Grizzly,
          ~r/^Grizzly\.Associations/,
          Grizzly.BackgroundRSSIMonitor,
          Grizzly.Events,
          Grizzly.Inclusions,
          Grizzly.Indicator,
          Grizzly.Network,
          Grizzly.Node,
          Grizzly.Options,
          Grizzly.Report,
          Grizzly.Supervisor,
          Grizzly.Trace,
          Grizzly.Trace.Record
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
        "Firmware Updates": [
          ~r/^Grizzly\.FirmwareUpdates/
        ],
        Requests: [
          ~r/^Grizzly\.(Requests)/
        ],
        Storage: [
          ~r/^Grizzly\.Storage/
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
          ~r/^Grizzly\.ZWave\.Security/,
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
        Grizzly.VirtualDevices,
        Grizzly.ZWave.CommandClasses,
        Grizzly.ZWave.Commands
      ],
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script defer src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
      let initialized = false;

      window.addEventListener("exdoc:loaded", () => {
        if (!initialized) {
          mermaid.initialize({
            startOnLoad: false,
            theme: document.body.className.includes("dark") ? "dark" : "default"
          });
          initialized = true;
        }

        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""
end
