defmodule Grizzly.Inclusions.InclusionRunnerSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.Inclusions
  alias Grizzly.Inclusions.InclusionRunner

  def start_link(grizzly_options) do
    DynamicSupervisor.start_link(__MODULE__, grizzly_options, name: __MODULE__)
  end

  @spec start_runner([Inclusions.opt()]) :: DynamicSupervisor.on_start_child()
  def start_runner(opts \\ []) do
    opts = ensure_handler(opts)
    child_spec = InclusionRunner.child_spec(opts)
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl DynamicSupervisor
  def init(grizzly_options) do
    # Only one inclusion runner can be running at a time
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_children: 1,
      extra_arguments: [grizzly_options]
    )
  end

  defp ensure_handler(opts) do
    Keyword.put_new_lazy(opts, :handler, &get_inclusion_handler/0)
  end

  defp get_inclusion_handler() do
    case Application.get_env(:grizzly, :handlers) do
      nil ->
        self()

      handlers ->
        Map.get(handlers, :inclusion, self())
    end
  end
end
