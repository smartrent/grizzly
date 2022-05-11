defmodule Grizzly.VirtualDevicesSupervisor do
  @moduledoc false

  use Supervisor

  alias Grizzly.VirtualDevices.{DevicesSupervisor, Network}

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
      {Registry, [keys: :unique, name: Grizzly.VirtualDevicesRegistry]},
      {Network, [inclusion_handler: grizzly_opts.inclusion_handler]},
      {DevicesSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
