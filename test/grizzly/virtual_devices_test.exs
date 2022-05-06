defmodule Grizzly.VirtualDeviceTest do
  use Grizzly.VirtualDeviceCase, async: true

  alias Grizzly.VirtualDevices
  alias Grizzly.VirtualDevices.Thermostat

  test "Adding devices to the network and getting them back" do
    with_virtual_devices(Thermostat, fn ids ->
      network_ids = VirtualDevices.list_nodes()

      for nid <- network_ids do
        assert nid in ids
      end
    end)
  end
end
