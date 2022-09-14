defmodule Grizzly.VirtualDevices.ThermostatTest do
  use Grizzly.VirtualDeviceCase

  alias Grizzly.{Node, Report}
  alias Grizzly.VirtualDevices.Thermostat
  alias Grizzly.ZWave.Command

  test "get thermostat node info" do
    {:ok, pid} = start_supervised({Thermostat, []})

    device_id =
      Grizzly.VirtualDevices.add_device(
        Thermostat,
        module: Thermostat,
        server: pid
      )

    Thermostat.set_device_id(pid, device_id)

    [device_id] = Grizzly.VirtualDevices.list_nodes()

    assert {:ok, %Report{type: :command, command: command}} = Node.get_info(device_id)

    assert command.name == :node_info_cache_report
  end

  test "get thermostat manufacture info" do
    {:ok, pid} = start_supervised({Thermostat, []})

    device_id =
      Grizzly.VirtualDevices.add_device(
        Thermostat,
        module: Thermostat,
        server: pid
      )

    Thermostat.set_device_id(pid, device_id)

    [device_id] = Grizzly.VirtualDevices.list_nodes()

    assert {:ok, %Report{type: :command, command: command}} =
             Grizzly.send_command(device_id, :manufacturer_specific_get)

    assert command.name == :manufacturer_specific_report
    assert Command.param!(command, :manufacturer_id) == 0x000
    assert Command.param!(command, :product_id) == 0x000
    assert Command.param!(command, :product_type_id) == 0x000
  end

  test "getting a command class version" do
    {:ok, pid} = start_supervised({Thermostat, []})

    device_id =
      Grizzly.VirtualDevices.add_device(
        Thermostat,
        module: Thermostat,
        server: pid
      )

    Thermostat.set_device_id(pid, device_id)

    [device_id] = Grizzly.VirtualDevices.list_nodes()

    assert {:ok, %Report{type: :command, command: command}} =
             Grizzly.send_command(device_id, :version_command_class_get,
               command_class: :thermostat_set_point
             )

    assert command.name == :version_command_class_report

    assert Command.param!(command, :version) == 2
  end

  describe "thermostat setpoints" do
    test "get cooling setpoint" do
      {:ok, pid} = start_supervised({Thermostat, []})

      device_id =
        Grizzly.VirtualDevices.add_device(
          Thermostat,
          module: Thermostat,
          server: pid
        )

      Thermostat.set_device_id(pid, device_id)
      [device_id] = Grizzly.VirtualDevices.list_nodes()

      assert {:ok, %Report{type: :command, command: command}} =
               Grizzly.send_command(device_id, :thermostat_setpoint_get, type: :cooling)

      assert command.name == :thermostat_setpoint_report
      assert Command.param!(command, :type) == :cooling
      assert Command.param!(command, :scale)
      assert Command.param!(command, :value)
    end

    test "get heating setpoint" do
      {:ok, pid} = start_supervised({Thermostat, []})

      device_id =
        Grizzly.VirtualDevices.add_device(
          Thermostat,
          module: Thermostat,
          server: pid
        )

      Thermostat.set_device_id(pid, device_id)
      [device_id] = Grizzly.VirtualDevices.list_nodes()

      assert {:ok, %Report{type: :command, command: command}} =
               Grizzly.send_command(device_id, :thermostat_setpoint_get, type: :heating)

      assert command.name == :thermostat_setpoint_report
      assert Command.param!(command, :type) == :heating
      assert Command.param!(command, :scale)
      assert Command.param!(command, :value)
    end

    test "set heating setpoint" do
      {:ok, pid} = start_supervised({Thermostat, []})

      device_id =
        Grizzly.VirtualDevices.add_device(
          Thermostat,
          module: Thermostat,
          server: pid
        )

      Thermostat.set_device_id(pid, device_id)
      [device_id] = Grizzly.VirtualDevices.list_nodes()

      assert {:ok, %Report{type: :ack_response}} =
               Grizzly.send_command(device_id, :thermostat_setpoint_set,
                 type: :heating,
                 scale: :celsius,
                 value: 21
               )

      {:ok, %Report{type: :command, command: command}} =
        Grizzly.send_command(device_id, :thermostat_setpoint_get, type: :heating)

      assert Command.param!(command, :value) == 21
    end
  end

  describe "sensor multilevel" do
    test "supported get" do
      {:ok, pid} = start_supervised({Thermostat, []})

      device_id =
        Grizzly.VirtualDevices.add_device(
          Thermostat,
          module: Thermostat,
          server: pid
        )

      Thermostat.set_device_id(pid, device_id)
      [device_id] = Grizzly.VirtualDevices.list_nodes()

      {:ok, %Report{type: :command, command: command}} =
        Grizzly.send_command(device_id, :sensor_multilevel_supported_sensor_get)

      assert command.name == :sensor_multilevel_supported_sensor_report
      assert Command.param!(command, :sensor_types) == [:temperature]
    end
  end
end
