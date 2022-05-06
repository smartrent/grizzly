defmodule Grizzly.VirtualDevices do
  @moduledoc """
  Virtual devices

  Virtual devices are in-memory devices that act like a Z-Wave device
  """

  alias Grizzly.VirtualDevices.{Device, DeviceServer, Network}
  alias Grizzly.ZWave.Command

  @typedoc """
  Id for a virtual device
  """
  @type id() :: {:virtual, integer()}

  @doc """
  Add a new virtual device to the virtual device network

  To add a virtual device you must supply a module that implements the
  `Grizzly.VirtualDevices.Device` behaviour.
  """
  @spec add_device(Device.t()) :: {:ok, id()}
  def add_device(device) do
    Network.add_device(device)
  end

  @doc """
  Send a Z-Wave command to a virtual device
  """
  @spec send_command(id(), Command.t()) :: Grizzly.send_command_response()
  def send_command(node_id, command) do
    DeviceServer.send_command(node_id, command)
  end

  @doc """
  Remove a virtual device from the virtual device network
  """
  @spec remove_device(id()) :: :ok
  def remove_device(virtual_device_id) do
    Network.remove_device(virtual_device_id)
  end

  @doc """
  List all the virtual devices on the virtual device network
  """
  @spec list_nodes() :: [id()]
  def list_nodes() do
    Network.list_nodes()
  end
end
