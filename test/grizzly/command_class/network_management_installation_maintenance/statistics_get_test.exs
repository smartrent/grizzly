defmodule Grizzly.CommandClass.NetworkManagementInstallationMaintenance.StatisticsGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementInstallationMaintenance.StatisticsGet

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %StatisticsGet{}} = StatisticsGet.init(node_id: 0x05)
    end

    test "encodes correctly" do
      node_id = 0x05
      {:ok, command} = StatisticsGet.init(seq_number: 0x08, node_id: node_id)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x67, 0x04, node_id>>

      assert {:ok, binary} == StatisticsGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = StatisticsGet.init(seq_number: 0x10, node_id: 0x05)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %StatisticsGet{}} = StatisticsGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = StatisticsGet.init(seq_number: 0x10, retries: 0, node_id: 0x05)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               StatisticsGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = StatisticsGet.init(seq_number: 0x10, node_id: 0x05)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = StatisticsGet.handle_response(command, packet)
    end

    test "handles NetworkManagementInstallationMaintenance report responses" do
      value = %{
        node_id: 5,
        statistics: %{
          route_changes: 1,
          transmission_count: 2,
          neighbors: [
            %{node_id: 7, repeater: false, speed: :"40 kbit/sec"},
            %{node_id: 8, repeater: true, speed: :"100 kbit/sec"}
          ],
          packet_error_count: 4,
          transmission_times_average: 200,
          transmission_time_variance: 40_000
        }
      }

      report = %{
        command_class: :network_management_installation_maintenance,
        command: :statistics_report,
        value: value
      }

      {:ok, command} = StatisticsGet.init([])
      packet = Packet.new(body: report)

      assert {:done, {:ok, value}} == StatisticsGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = StatisticsGet.init(seq_number: 0x01, command_class: :switch_binary)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = StatisticsGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = StatisticsGet.init(seq_number: 0x01, node_id: 0x05)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = StatisticsGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = StatisticsGet.init(node_id: 0x05)

      assert {:continue, %StatisticsGet{node_id: 0x05}} ==
               StatisticsGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
