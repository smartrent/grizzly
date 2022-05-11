defmodule Grizzly.VirtualDevices do
  @moduledoc """
  Virtual devices

  Virtual devices are in-memory devices that act like a Z-Wave device
  """

  alias Grizzly.VirtualDevices.{Device, DeviceServer, Network}
  alias Grizzly.ZWave.Command

  @typedoc """
  Options for adding a virtual devices

  * `:inclusion_handler` - if an inclusion handler is provider via the add
    options it will override the initial inclusion handle argument to the
    network server if one was provided only for that one call to `add_device/2`.
  """
  @type add_opt() :: {:inclusion_handler, Grizzly.handler()}

  @typedoc """
  Options for removing virtual devices

  * `:inclusion_handler` - if an inclusion handler is provider via the add
    options it will override the initial inclusion handle argument to the
    network server if one was provided only for that one call to
    `remove_device/2`.
  """
  @type remove_opt() :: {:inclusion_handler, Grizzly.handler()}

  @typedoc """
  Id for a virtual device
  """
  @type id() :: {:virtual, integer()}

  @doc """
  Add a new virtual device to the virtual device network

  To add a virtual device you must supply a module that implements the
  `Grizzly.VirtualDevices.Device` behaviour.
  """
  @spec add_device(Device.t(), [add_opt()]) :: {:ok, id()}
  def add_device(device, opts \\ []) do
    Network.add_device(device, opts)
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
  @spec remove_device(id(), [remove_opt()]) :: :ok
  def remove_device(virtual_device_id, opts \\ []) do
    Network.remove_device(virtual_device_id, opts)
  end

  @doc """
  List all the virtual devices on the virtual device network
  """
  @spec list_nodes() :: [id()]
  def list_nodes() do
    Network.list_nodes()
  end
end
