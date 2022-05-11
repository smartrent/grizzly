defmodule Grizzly.VirtualDeviceTest do
  use Grizzly.VirtualDeviceCase, async: true

  import ExUnit.CaptureLog

  alias Grizzly.VirtualDevices
  alias Grizzly.VirtualDevices.Thermostat

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
    with_virtual_devices(Thermostat, fn ids ->
      network_ids = VirtualDevices.list_nodes()

      for nid <- network_ids do
        assert nid in ids
      end
    end)
  end

  test "Add and remove device ensure status reports are sent to configured handler" do
    log = capture_log(fn -> VirtualDevices.add_device(Thermostat) end)

    device_id = parse_node_id_from_log(log)

    assert {:virtual, _id} = device_id
    assert log =~ "node_add_status"

    log = capture_log(fn -> VirtualDevices.remove_device(device_id) end)

    assert log =~ "node_remove_status"
    assert log =~ "#{inspect(device_id)}"
  end

  test "Add and device with ensure status reports are sent with function inclusion handler" do
    {:ok, device_id} =
      VirtualDevices.add_device(Thermostat, inclusion_handler: {Handler, [test: &add_test/1]})

    :ok =
      VirtualDevices.remove_device(device_id,
        inclusion_handler: {Handler, [test: &remove_test(device_id, &1)]}
      )
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
    [[vid_str] | _rest] = Regex.scan(~r/\{\:virtual, [0-9]\}/, log)

    [_, id_str] = String.split(vid_str)

    {id, _} =
      id_str
      |> String.trim()
      |> String.replace("}", "")
      |> Integer.parse()

    {:virtual, id}
  end
end
