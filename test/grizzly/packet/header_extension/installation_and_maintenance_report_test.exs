defmodule Grizzly.Packet.HeaderExtension.InstallationAndMaintenanceReport.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet.HeaderExtension.InstallationAndMaintenanceReport

  describe "decoding IMEs" do
    test "route changed" do
      assert {{:route_changed, :changed}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(<<0x00, 0x01, 0x01>>)

      assert {{:route_changed, :not_changed}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(<<0x00, 0x01, 0x00>>)
    end

    test "transmission time" do
      assert {{:transmission_time, 1}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(<<0x01, 0x02, 0x00, 0x01>>)
    end

    test "last working route" do
      packet_base = <<0x02, 0x05, 0x01, 0x02, 0x03, 0x04>>

      assert {{:last_working_route, {1, 2, 3, 4}, {100, :kbit_sec}}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(packet_base <> <<0x03>>)

      assert {{:last_working_route, {1, 2, 3, 4}, {40, :kbit_sec}}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(packet_base <> <<0x02>>)

      assert {{:last_working_route, {1, 2, 3, 4}, {9.6, :kbit_sec}}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(packet_base <> <<0x01>>)

      assert {{:last_working_route, {1, 2, 3, 4}, {:unknown, 0x05}}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(packet_base <> <<0x05>>)
    end

    test "rssi" do
      binary = <<0x03, 0x05, 0x7E, 0x7F, 0x7D, -32, -94>>

      assert {{:rssi, {:max_power_saturated, :not_available, :below_sensitivity, -32, -94}}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary)
    end

    test "ack channel" do
      binary = <<0x04, 0x01, 0xFF>>

      assert {{:ack_channel, 0xFF}, _} = InstallationAndMaintenanceReport.ime_from_binary(binary)
    end

    test "transmit channel" do
      binary = <<0x05, 0x01, 0xA0>>

      assert {{:transmit_channel, 0xA0}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary)
    end

    test "routing scheme" do
      binary_base = <<0x06, 0x01>>

      assert {{:routing_scheme, :idle}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x00>>)

      assert {{:routing_scheme, :direct_transmission_no_routing}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x01>>)

      assert {{:routing_scheme, :application_static_route}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x02>>)

      assert {{:routing_scheme, :last_working_route}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x03>>)

      assert {{:routing_scheme, :next_to_last_working_route}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x04>>)

      assert {{:routing_scheme, :return_route_or_controller_auto_route}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x05>>)

      assert {{:routing_scheme, :direct_resort}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x06>>)

      assert {{:routing_scheme, :explorer_frame}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x07>>)

      assert {{:routing_scheme, {:unknown, 0x77}}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary_base <> <<0x77>>)
    end

    test "number of attempts" do
      binary = <<0x07, 0x01, 0x10>>

      assert {{:routing_attempts, 0x10}, _} =
               InstallationAndMaintenanceReport.ime_from_binary(binary)
    end

    test "failed link" do
      binary = <<0x08, 0x02, 1, 2>>

      assert {{:failed_link, 1, 2}, _} = InstallationAndMaintenanceReport.ime_from_binary(binary)
    end
  end

  test "parse imes from report" do
    report = <<0x03, 0x06, 0x00, 0x01, 0x01, 0x05, 0x01, 0xFF>>

    expected_results =
      InstallationAndMaintenanceReport.new([{:route_changed, :changed}, {:transmit_channel, 0xFF}])

    assert expected_results == InstallationAndMaintenanceReport.from_binary(report)
  end
end
