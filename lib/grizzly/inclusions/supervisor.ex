defmodule Grizzly.Inclusions.Supervisor do
  @moduledoc false

  # Supervisor to manage the life cycle of inclusion related processes

  use Supervisor

  alias Grizzly.Options

  @doc """
  Start the Inclusions supervisor
  """
  @spec start_link(Options.t()) :: Supervisor.on_start()
  def start_link(options) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl Supervisor
  def init(options) do
    children = [
      Grizzly.Inclusions.StatusServer,
      {Grizzly.InclusionServer, options}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
