defmodule Grizzly.Controller.Supervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    children = [
      {Grizzly.Controller, get_grizzly_config()},
      Grizzly.Network.Server
    ]

    opts = [strategy: :one_for_all]
    Supervisor.init(children, opts)
  end

  defp get_grizzly_config() do
    case Application.get_env(:grizzly, Grizzly.Controller) do
      nil -> Grizzly.config()
      opts -> Grizzly.Conn.Config.new(opts)
    end
  end
end
