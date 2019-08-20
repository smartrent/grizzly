defmodule Grizzly.CommandClass.NetworkManagementInstallationMaintenance.RSSIGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementInstallationMaintenance.RSSIGet

  describe "implements Grizzly.Command behaviour" do
    test "initializes to the correct command state" do
      assert {:ok, %RSSIGet{}} = RSSIGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = RSSIGet.init(seq_number: 0x08)
      binary = <<35, 2, 128, 208, 8, 0, 0, 3, 2, 0, 0x67, 0x07>>

      assert {:ok, binary} == RSSIGet.encode(command)
    end

    test "handles ack response" do
      {:ok, command} = RSSIGet.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:ack_response])

      assert {:continue, %RSSIGet{}} = RSSIGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = RSSIGet.init(seq_number: 0x10, retries: 0)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:done, {:error, :nack_response}} ==
               RSSIGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = RSSIGet.init(seq_number: 0x10)
      packet = Packet.new(seq_number: 0x10, types: [:nack_response])

      assert {:retry, _command} = RSSIGet.handle_response(command, packet)
    end

    test "handles NetworkManagementInstallationMaintenance report responses" do
      value = [:power_saturated, :below_sensitivity, :above_sensitivity]

      report = %{
        command_class: :network_management_installation_maintenance,
        command: :rssi_report,
        value: value
      }

      {:ok, command} = RSSIGet.init([])
      packet = Packet.new(body: report)

      assert {:done, {:ok, value}} == RSSIGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = RSSIGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = RSSIGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = RSSIGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = RSSIGet.handle_response(command, packet)
    end

    test "handles response" do
      {:ok, command} = RSSIGet.init([])

      assert {:continue, %RSSIGet{}} ==
               RSSIGet.handle_response(
                 command,
                 %{command_class: :door_lock, value: :foo, command: :report}
               )
    end
  end
end
