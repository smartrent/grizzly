defmodule Grizzly.VirtualDevices.ThermostatTest do
  use Grizzly.VirtualDeviceCase

  alias Grizzly.{Node, Report}
  alias Grizzly.VirtualDevices.Thermostat
  alias Grizzly.ZWave.Command

  test "get thermostat node info" do
    with_virtual_device(Thermostat, fn id ->
      assert {:ok, %Report{type: :command, command: command}} = Node.get_info(id)

      assert command.name == :node_info_cache_report
    end)
  end

  test "get thermostat manufacture info" do
    with_virtual_device(Thermostat, fn id ->
      assert {:ok, %Report{type: :command, command: command}} =
               Grizzly.send_command(id, :manufacturer_specific_get)

      assert command.name == :manufacturer_specific_report
      assert Command.param!(command, :manufacturer_id) == 0x000
      assert Command.param!(command, :product_id) == 0x000
      assert Command.param!(command, :product_type_id) == 0x000
    end)
  end

  test "getting a command class version" do
    with_virtual_device(Thermostat, fn id ->
      assert {:ok, %Report{type: :command, command: command}} =
               Grizzly.send_command(id, :version_command_class_get,
                 command_class: :thermostat_set_point
               )

      assert command.name == :version_command_class_report

      assert Command.param!(command, :version) == 2
    end)
  end

  describe "thermostat setpoints" do
    test "get cooling setpoint" do
      with_virtual_device(Thermostat, fn id ->
        assert {:ok, %Report{type: :command, command: command}} =
                 Grizzly.send_command(id, :thermostat_setpoint_get, type: :cooling)

        assert command.name == :thermostat_setpoint_report
        assert Command.param!(command, :type) == :cooling
        assert Command.param!(command, :scale)
        assert Command.param!(command, :value)
      end)
    end

    test "get heating setpoint" do
      with_virtual_device(Thermostat, fn id ->
        assert {:ok, %Report{type: :command, command: command}} =
                 Grizzly.send_command(id, :thermostat_setpoint_get, type: :heating)

        assert command.name == :thermostat_setpoint_report
        assert Command.param!(command, :type) == :heating
        assert Command.param!(command, :scale)
        assert Command.param!(command, :value)
      end)
    end

    test "set heating setpoint" do
      with_virtual_device(Thermostat, fn id ->
        assert {:ok, %Report{type: :ack_response}} =
                 Grizzly.send_command(id, :thermostat_setpoint_set,
                   type: :heating,
                   scale: :celsius,
                   value: 21
                 )

        {:ok, %Report{type: :command, command: command}} =
          Grizzly.send_command(id, :thermostat_setpoint_get, type: :heating)

        assert Command.param!(command, :value) == 21
      end)
    end
  end

  describe "sensor multilevel" do
    test "supported get" do
      with_virtual_device(Thermostat, fn id ->
        {:ok, %Report{type: :command, command: command}} =
          Grizzly.send_command(id, :sensor_multilevel_supported_sensor_get)

        assert command.name == :sensor_multilevel_supported_sensor_report
        assert Command.param!(command, :sensor_types) == [:temperature]
      end)
    end
  end
end
