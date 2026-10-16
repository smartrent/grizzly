defmodule Grizzly.Backend do
  @moduledoc "The backend fixed into this build. Runtime selection/fallback is forbidden."

  @backend Application.compile_env(:grizzly, :backend, :zipgateway)
  if @backend != Mix.Project.config()[:grizzly_backend],
    do: raise(ArgumentError, "application backend differs from GRIZZLY_BACKEND build profile")

  unless @backend in [:zipgateway, :zwrap], do: raise(ArgumentError, "invalid compiled backend")

  @doc "Whether the native backend is compiled into this release."
  def zwrap?(), do: @backend == :zwrap

  @spec name() :: :zipgateway | :zwrap
  def name(), do: @backend

  @runtime if @backend == :zwrap, do: Grizzly.Backends.Zwrap, else: Grizzly.Backends.Zipgateway

  @doc false
  defdelegate children(options), to: @runtime
  @doc false
  defdelegate post_children(options), to: @runtime
  @doc false
  defdelegate connection_spec(node, opts), to: @runtime
  @doc false
  defdelegate zipgateway_operation(operation), to: @runtime
  @doc false
  defdelegate ready?(), to: @runtime
  @doc false
  defdelegate controller_id(), to: @runtime
  @doc false
  defdelegate home_id(), to: @runtime
  @doc false
  defdelegate network_keys(), to: @runtime
  @doc false
  defdelegate zniffer_network_keys(), to: @runtime
  @doc false
  defdelegate listening_mode(node), to: @runtime

  @doc false
  def validate!() do
    if Application.get_env(:grizzly, :backend, @backend) != @backend do
      raise ArgumentError,
            "runtime backend configuration differs from compiled backend #{@backend}"
    end

    :ok
  end
end
