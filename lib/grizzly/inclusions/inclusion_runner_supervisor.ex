defmodule Grizzly.Inclusions.InclusionRunnerSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.Inclusions
  alias Grizzly.Inclusions.InclusionRunner

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec start_runner([Inclusions.opt()]) :: DynamicSupervisor.on_start_child()
  def start_runner(opts \\ []) do
    opts = Keyword.merge([handler: self()], opts)
    child_spec = InclusionRunner.child_spec(opts)
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_) do
    # Only one inclusion runner can be running at a time
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 1)
  end
end
