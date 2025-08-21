defmodule Grizzly.VirtualDeviceTest do
  use Grizzly.VirtualDeviceCase

  import ExUnit.CaptureLog

  alias Grizzly.{Node, Report, VirtualDevices}
  alias Grizzly.VirtualDevices.{TemperatureSensor, Thermostat}
  alias Grizzly.ZWave.Command

  defmodule Handler do
    @moduledoc false
    @behaviour Grizzly.InclusionHandler

    alias Grizzly.Report

    def handle_report(%Report{type: :command, command: command}, opts) do
      test = Keyword.fetch!(opts, :test)

      test.(command)

      :ok
    end

    def handle_timeout(_, _), do: :ok
  end

  test "Adding devices to the network and getting them back" do
    device_ids =
      Enum.map(1..5, fn _ ->
        VirtualDevices.add_device!(generate_id(), Thermostat)
      end)

    expected_devices = VirtualDevices.list_nodes()

    for id <- device_ids do
      assert id in expected_devices
    end
  end

  test "Add and remove device ensure status reports are sent to configured handler" do
    log =
      capture_log(fn ->
        VirtualDevices.add_device!(generate_id(), Thermostat)
      end)

    device_id = parse_node_id_from_log(log)

    assert {:virtual, _id} = device_id
    assert log =~ "node_add_status"

    log = capture_log(fn -> VirtualDevices.remove_device(device_id) end)

    assert log =~ "node_remove_status"
    assert log =~ "#{inspect(device_id)}"
  end

  test "Add and device with ensure status reports are sent with function inclusion handler" do
    device_id =
      VirtualDevices.add_device!(generate_id(), Thermostat,
        inclusion_handler: {Handler, [test: &add_test/1]}
      )

    :ok =
      VirtualDevices.remove_device(device_id,
        inclusion_handler: {Handler, [test: &remove_test(device_id, &1)]}
      )
  end

  test "associate virtual device to lifeline association" do
    with_virtual_device(Thermostat, fn id ->
      {:ok, %Report{type: :ack_response}} = Node.set_lifeline_association(id)

      {:ok, %Report{type: :command, command: command}} =
        Grizzly.send_command(id, :association_get, grouping_identifier: 1)

      assert Command.param!(command, :nodes) == [1]
    end)
  end

  describe "battery reports" do
    test "getting a battery report" do
      with_virtual_device(Thermostat, fn id ->
        {:ok, %Report{type: :command, command: command}} = Grizzly.send_command(id, :battery_get)

        assert command.name == :battery_report
        assert Command.param!(command, :level) == 100
      end)
    end
  end

  describe "version get reports" do
    test "routing end node" do
      with_virtual_device(Thermostat, fn id ->
        {:ok, %Report{type: :command, command: command}} = Grizzly.send_command(id, :version_get)

        assert command.name == :version_report
        assert Command.param!(command, :library_type) == :routing_end_node
      end)
    end
  end

  test "handles device specific get for device id type serial number" do
    with_virtual_device(Thermostat, fn id ->
      {:ok, %Report{type: :command, command: command}} =
        Grizzly.send_command(id, :manufacturer_specific_device_specific_get,
          device_id_type: :serial_number
        )

      assert command.name == :manufacturer_specific_device_specific_report
    end)
  end

  test "receives notification for sensor report" do
    {:ok, pid} = start_supervised({TemperatureSensor, report_interval: 100, force_report: true})

    device_id =
      Grizzly.VirtualDevices.add_device!(
        generate_id(),
        Thermostat,
        module: Thermostat,
        server: pid
      )

    Thermostat.set_device_id(pid, device_id)

    Grizzly.subscribe(:sensor_multilevel_report)

    assert_receive {:grizzly, :report, report}, 500

    assert report.command.name == :sensor_multilevel_report
  end

  defp add_test(%{name: :node_add_status, params: params}) do
    assert {:virtual, _} = Keyword.fetch!(params, :node_id)
    assert :done == Keyword.fetch!(params, :status)
  end

  defp remove_test(device_id, %{name: :node_remove_status, params: params}) do
    assert device_id == Keyword.fetch!(params, :node_id)
    assert :done == Keyword.fetch!(params, :status)
  end

  defp parse_node_id_from_log(log) do
    [[vid_str] | _rest] = Regex.scan(~r/\{\:virtual, \d+\}/, log)

    [_, id_str] = String.split(vid_str)

    {id, _} =
      id_str
      |> String.trim()
      |> String.replace("}", "")
      |> Integer.parse()

    {:virtual, id}
  end
end
