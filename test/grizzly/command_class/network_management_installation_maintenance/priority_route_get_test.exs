defmodule Grizzly.CommandClass.NetworkManagementInstallationMaintenance.PriorityRouteGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementInstallationMaintenance.PriorityRouteGet

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %PriorityRouteGet{}} = PriorityRouteGet.init(node_id: 0x05)
    end

    test "encodes correctly" do
      node_id = 0x05
      {:ok, command} = PriorityRouteGet.init(seq_number: 0x08, node_id: node_id)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x67, 0x02, node_id>>

      assert {:ok, binary} == PriorityRouteGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = PriorityRouteGet.init(seq_number: 0x10, node_id: 0x05)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %PriorityRouteGet{}} = PriorityRouteGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = PriorityRouteGet.init(seq_number: 0x10, retries: 0, node_id: 0x05)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               PriorityRouteGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = PriorityRouteGet.init(seq_number: 0x10, node_id: 0x05)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = PriorityRouteGet.handle_response(command, packet)
    end

    test "handles NetworkManagementInstallationMaintenance report responses" do
      value = %{node_id: 5, repeaters: [7, 8], type: :last_working_route, speed: :"100 kbit/sec"}

      report = %{
        command_class: :network_management_installation_maintenance,
        command: :priority_route_report,
        value: value
      }

      {:ok, command} = PriorityRouteGet.init(node_id: 0x05)
      packet = Packet.new(body: report)

      assert {:done, {:ok, value}} == PriorityRouteGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = PriorityRouteGet.init(seq_number: 0x01, command_class: :switch_binary)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = PriorityRouteGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = PriorityRouteGet.init(seq_number: 0x01, node_id: 0x05)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = PriorityRouteGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = PriorityRouteGet.init(node_id: 0x05)

      assert {:continue, %PriorityRouteGet{node_id: 0x05}} ==
               PriorityRouteGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
