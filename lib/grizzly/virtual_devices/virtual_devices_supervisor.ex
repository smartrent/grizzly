defmodule Grizzly.VirtualDevicesSupervisor do
  @moduledoc false

  use Supervisor

  alias Grizzly.VirtualDevicesRegistry

  @doc """
  Start the VirtualDevices Supervisor
  """
  @spec start_link(Grizzly.Options.t()) :: Supervisor.on_start()
  def start_link(grizzly_options) do
    Supervisor.start_link(__MODULE__, grizzly_options, name: __MODULE__)
  end

  @impl Supervisor
  def init(grizzly_opts) do
    children = [
      {Registry, VirtualDevicesRegistry.start_options(grizzly_opts)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
