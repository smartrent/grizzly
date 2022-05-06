defmodule Grizzly.VirtualDevices.DevicesSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias Grizzly.VirtualDevices
  alias Grizzly.VirtualDevices.{Device, DeviceServer}

  @doc """
  Start the devices supervisor
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Start the device server under this supervisor
  """
  @spec start_device(VirtualDevices.id(), Device.t()) :: DynamicSupervisor.on_start_child()
  def start_device(device_id, device) do
    spec = DeviceServer.child_spec(id: device_id, device: device)

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
