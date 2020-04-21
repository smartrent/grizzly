defmodule Grizzly.MixProject do
  use Mix.Project

  def project do
    [
      app: :grizzly,
      version: "0.8.2",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :asn1, :public_key, :ssl],
      mod: {Grizzly.Application, []}
    ]
  end

  def elixirc_paths(:test), do: ["test/support", "lib"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.3", only: [:test, :dev], runtime: false},
      {:muontrap, "~> 0.4"},
      {:ex_doc, "~> 0.19", only: :docs, runtime: false}
    ]
  end

  defp dialyzer() do
    [
      ignore_warnings: "dialyzer.ignore-warnings",
      flags: [:unmatched_returns, :error_handling, :race_conditions]
    ]
  end

  defp description do
    "Z-Wave Z/IP gateway client"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/smartrent/grizzly"}
    ]
  end

  defp docs() do
    [
      extras: ["README.md"],
      main: "readme",
      logo: "./assets/grizzly-icon-yellow.png",
      source_url: "https://github.com/smartrent/grizzly"
    ]
  end

  defp aliases() do
    [
      test: ["test --exclude integration --exclude inclusion"]
    ]
  end
end
