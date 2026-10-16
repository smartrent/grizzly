Code.require_file("build_support/backend_profile.exs", __DIR__)

defmodule Grizzly.MixProject do
  use Mix.Project

  @version "9.1.5"
  @backend (case System.get_env("GRIZZLY_BACKEND", "zipgateway") do
              "zipgateway" -> :zipgateway
              "zwrap" -> :zwrap
              other -> raise "Invalid GRIZZLY_BACKEND: #{inspect(other)}"
            end)

  def project() do
    [
      app: :grizzly,
      grizzly_backend: @backend,
      version: @version,
      build_path: "_build/#{@backend}",
      test_paths: if(@backend == :zwrap, do: ["test_native"], else: ["test"]),
      elixir: "~> 1.16",
      elixirc_paths: Grizzly.BuildProfile.sources(@backend, Mix.env()),
      compilers: Mix.compilers() ++ [:grizzly_artifacts],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      description: description(),
      package: package(),
      docs: docs(),
      test_coverage: [
        ignore_modules: [~r/^GrizzlyTest/, ~r/^Mock/, ~r/^Mix/],
        summary: [threshold: 0]
      ]
    ]
  end

  def application() do
    [
      extra_applications:
        [:logger, :crypto, :sasl] ++ if(@backend == :zipgateway, do: [:ssl], else: [])
    ]
  end

  def cli() do
    [
      preferred_envs: ["hex.publish": :docs, docs: :docs, dialyzer: :test]
    ]
  end

  defp deps() do
    [
      # Opt in locally; downstream applications can supply their own :zwrap dependency.
      {:alarmist, "~> 0.4", only: [:test]},
      {:cerlc, "~> 0.2"},
      {:circuits_uart, "~> 1.0"},
      {:circular_buffer, "~> 1.0 or ~> 0.4.2"},
      {:credo_binary_patterns, "~> 0.2.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.0", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.21", only: [:docs, :test], runtime: false},
      {:exmodem, "~> 0.1"},
      {:exqlite, "~> 0.33"},
      {:junit_formatter, "~> 3.3", only: :test},
      {:mimic, "~> 2.0", only: [:dev, :test]},
      {:nimble_options, "~> 1.0"},
      {:property_table, "~> 0.3"},
      {:quokka, "~> 2.11", only: [:dev, :test], runtime: false},
      {:sweet_xml, "~> 0.7", only: [:dev, :test]},
      {:telemetry_registry, "~> 0.3"},
      {:telemetry, "~> 0.4.3 or ~> 1.0"}
    ] ++ backend_deps()
  end

  defp backend_deps() do
    if @backend == :zipgateway do
      [
        {:beam_notify, "~> 1.0 or ~> 0.2.0"},
        {:ctr_drbg, "~> 0.1"},
        {:muontrap, "~> 2.0 or ~> 1.0"},
        {:thousand_island, "~> 1.3"}
      ]
    else
      zwrap_dep()
    end
  end

  defp zwrap_dep() do
    if @backend == :zwrap do
      path = System.get_env("GRIZZLY_ZWRAP_PATH") || "../zipato-zwrap-parity"
      [{:zwrap, path: Path.expand(path)}]
    else
      []
    end
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
      plt_add_apps: [:mix, :ex_unit]
    ] ++ ci_opts
  end

  defp description() do
    "Elixir Z-Wave library"
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      files: ["lib", "priv", "build_support", "mix.exs", "README.md", "CHANGELOG.md"],
      links: %{"GitHub" => "https://github.com/smartrent/grizzly"}
    ]
  end

  defp docs() do
    [
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/cookbook.md",
        "docs/backends.md",
        "docs/zwrap-unsupported.md"
      ],
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
        "Command Definitions": [
          Grizzly.ZWave.Command,
          Grizzly.ZWave.Commands,
          Grizzly.ZWave.CommandSpec,
          Grizzly.ZWave.ParamSpec
        ],
        Behaviours: [
          Grizzly.CommandHandler,
          Grizzly.FirmwareUpdateHandler,
          Grizzly.InclusionHandler
        ],
        "Virtual Devices": [
          Grizzly.VirtualDevices,
          Grizzly.VirtualDevices.Device
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
          Grizzly.ZWave.CommandClass,
          Grizzly.ZWave.DeviceClass,
          Grizzly.ZWave.DeviceClasses,
          Grizzly.ZWave.DSK,
          Grizzly.ZWave.Encoding,
          Grizzly.ZWave.IconType,
          Grizzly.ZWave.Notifications,
          Grizzly.ZWave.QRCode,
          ~r/^Grizzly\.ZWave\.Security/,
          ~r/^Grizzly\.ZWave\.SmartStart/,
          Grizzly.ZWave.ZWEnum,
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
