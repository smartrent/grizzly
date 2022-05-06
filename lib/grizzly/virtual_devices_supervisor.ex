defmodule Grizzly.VirtualDevicesSupervisor do
  @moduledoc false

  use Supervisor

  alias Grizzly.VirtualDevices.{DevicesSupervisor, Network}

  @doc """
  Start the VirtualDevices Supervisor
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    children = [
      {Registry, [keys: :unique, name: Grizzly.VirtualDevicesRegistry]},
      {Network, []},
      {DevicesSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
