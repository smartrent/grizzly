defmodule Grizzly.BuildProfile do
  @moduledoc false
  # Codecs remain shared; controller/socket processes are profile-exclusive.
  @legacy_paths [
    "lib/grizzly/zipgateway/",
    "lib/grizzly/backends/zipgateway",
    "lib/grizzly/zip_gateway.ex",
    "lib/grizzly/transport.ex",
    "lib/grizzly/storage/populate.ex",
    "lib/grizzly/transports/",
    "lib/grizzly/unsolicited_server/connection_handler.ex",
    "lib/grizzly/unsolicited_server/dtls_transport.ex",
    "lib/grizzly/connections/binary_connection.ex",
    "lib/grizzly/connections/keep_alive.ex",
    "lib/grizzly/connections/request_list.ex"
  ]
  @native_paths ["lib/grizzly/backends/zwrap"]
  @legacy_support ["test/support/server/", "test/support/dtls.ex"]
  @legacy_modules [
    "Grizzly.ZIPGateway",
    "Grizzly.Backends.Zipgateway",
    "Grizzly.Transport",
    "Grizzly.Transports",
    "Grizzly.Storage.Populate",
    "Grizzly.UnsolicitedServer.ConnectionHandler",
    "Grizzly.UnsolicitedServer.DTLSTransport",
    "Grizzly.Connections.BinaryConnection",
    "Grizzly.Connections.KeepAlive",
    "Grizzly.Connections.RequestList"
  ]

  def sources(backend, env) do
    excluded = if backend == :zwrap, do: @legacy_paths, else: @native_paths
    sources = Path.wildcard("lib/**/*.ex") |> reject_prefixes(excluded)
    support = if env == :test, do: Path.wildcard("test/support/**/*.ex"), else: []
    support = if backend == :zwrap, do: reject_prefixes(support, @legacy_support), else: support
    support ++ sources
  end

  def excluded_module?(backend, module) do
    name = module |> to_string() |> String.trim_leading("Elixir.")
    prefixes = if backend == :zwrap, do: @legacy_modules, else: ["Grizzly.Backends.Zwrap"]

    Enum.any?(prefixes, fn prefix ->
      name == prefix or String.starts_with?(name, prefix <> ".") or
        String.contains?(name, "." <> prefix <> ".") or String.ends_with?(name, "." <> prefix)
    end)
  end

  defp reject_prefixes(paths, excluded),
    do: Enum.reject(paths, fn path -> Enum.any?(excluded, &String.starts_with?(path, &1)) end)
end

defmodule Mix.Tasks.Compile.GrizzlyArtifacts do
  use Mix.Task.Compiler

  @impl Mix.Task.Compiler
  def run(_) do
    backend = Mix.Project.config()[:grizzly_backend]
    compile_path = Mix.Project.compile_path()
    # Also prune obsolete BEAMs from earlier development builds. Source filtering
    # alone cannot remove files that were never in Mix's compiler manifest.
    for file <- Path.wildcard(Path.join(compile_path, "*.beam")),
        Grizzly.BuildProfile.excluded_module?(backend, Path.basename(file, ".beam")) do
      File.rm!(file)
    end

    prune_app(Path.join(compile_path, "grizzly.app"), backend)

    # Mix normally symlinks priv to the checkout. Remove the link itself first;
    # never delete certificates/scripts through a shared source-directory link.
    destination = Path.join(Mix.Project.app_path(), "priv")

    if backend == :zwrap do
      case File.lstat(destination) do
        {:ok, %{type: :symlink}} -> File.rm!(destination)
        _ -> :ok
      end

      File.rm_rf!(destination)
      File.mkdir_p!(destination)
    end

    {:noop, []}
  end

  defp prune_app(path, backend) do
    {:ok, [{:application, :grizzly, props}]} = :file.consult(String.to_charlist(path))
    modules = Enum.reject(props[:modules], &Grizzly.BuildProfile.excluded_module?(backend, &1))

    if modules != props[:modules] do
      data =
        :io_lib.format(~c"~tp.~n", [
          {:application, :grizzly, Keyword.put(props, :modules, modules)}
        ])

      File.write!(path, data)
    end
  end
end

defmodule Mix.Tasks.Grizzly.CheckBuild do
  @shortdoc "Assert the compiled backend, dependencies and private artifacts are isolated"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Mix.Task.run("compile")
    backend = Mix.Project.config()[:grizzly_backend]
    if Grizzly.Backend.name() != backend, do: Mix.raise("compiled backend does not match profile")
    files = Path.wildcard(Path.join(Mix.Project.compile_path(), "*.beam"))

    excluded =
      Enum.filter(
        files,
        &Grizzly.BuildProfile.excluded_module?(backend, Path.basename(&1, ".beam"))
      )

    if excluded != [], do: Mix.raise("inactive backend BEAMs: #{inspect(excluded)}")

    {:ok, [{:application, :grizzly, props}]} =
      :file.consult(String.to_charlist(Path.join(Mix.Project.compile_path(), "grizzly.app")))

    if Enum.any?(props[:modules], &Grizzly.BuildProfile.excluded_module?(backend, &1)),
      do: Mix.raise("inactive backend in application module inventory")

    excluded_apps =
      if backend == :zwrap,
        do: [:muontrap, :thousand_island, :beam_notify, :ctr_drbg],
        else: [:zwrap]

    dependencies = Mix.Project.deps_paths() |> Map.keys()

    if Enum.any?(excluded_apps, &(&1 in dependencies or &1 in props[:applications])),
      do: Mix.raise("inactive backend dependency in build graph")

    check_assets(backend)
    Mix.shell().info("#{backend} source/dependency/artifact isolation passed")
  end

  defp check_assets(:zwrap) do
    priv = Path.join(Mix.Project.app_path(), "priv")
    if File.ls!(priv) != [], do: Mix.raise("legacy assets in native Grizzly priv")
    # Use this build's dependency application path, not its source priv.
    app_priv = Path.join([Mix.Project.build_path(), "lib", "zwrap", "priv"])
    binary = Path.join(app_priv, "zwrap_port")

    metadata =
      app_priv
      |> Path.join("zwrap_port.manifest")
      |> File.read!()
      |> :erlang.binary_to_term([:safe])

    hash = Base.encode16(:crypto.hash(:sha256, File.read!(binary)), case: :lower)

    if metadata.sha256 != hash or metadata.environment != :prod or
         metadata.mix_target != Mix.target(),
       do: Mix.raise("native executable does not match target/environment manifest")

    case File.lstat(app_priv) do
      {:ok, %{type: :symlink}} -> Mix.raise("native executable priv still shares source symlink")
      _ -> :ok
    end
  end

  defp check_assets(:zipgateway) do
    for name <- ["zipgateway.cfg", "zipgateway.tun", "Portal.ca_x509.pem", "ZIPR.key_1024.pem"] do
      unless File.regular?(Path.join([Mix.Project.app_path(), "priv", name])),
        do: Mix.raise("missing legacy private artifact #{name}")
    end
  end
end
