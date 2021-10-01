defmodule Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.InstallationAndMaintenanceReport do
  @moduledoc """
  The installation and maintenance report for a Z/IP Packet
  """

  alias Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.BinaryParser

  def from_binary(<<0x03, length, rest::binary>>) do
    <<imes_bin::binary-size(length), _rest::binary>> = rest

    imes_bin
    |> BinaryParser.from_binary()
    |> BinaryParser.parse(&ime_from_binary/1)
  end

  def ime_from_binary(<<0x00, 0x01, route_changed, rest::binary>>) do
    {{:route_changed, parse_route_change_value(route_changed)}, rest}
  end

  def ime_from_binary(<<0x01, 0x02, transmission_time::integer-size(2)-unit(8), rest::binary>>) do
    {{:transmission_time, transmission_time}, rest}
  end

  def ime_from_binary(<<0x02, 0x05, r1, r2, r3, r4, speed, rest::binary>>) do
    {{:last_working_route, {r1, r2, r3, r4}, parse_transmission_speed(speed)}, rest}
  end

  def ime_from_binary(
        <<0x03, 0x05, hop1::signed-integer, hop2::signed-integer, hop3::signed-integer,
          hop4::signed-integer, hop5::signed-integer, rest::binary>>
      ) do
    {{:rssi_hops,
      [
        parse_rssi_hop(hop1),
        parse_rssi_hop(hop2),
        parse_rssi_hop(hop3),
        parse_rssi_hop(hop4),
        parse_rssi_hop(hop5)
      ]}, rest}
  end

  def ime_from_binary(<<0x04, 0x01, ack_channel, rest::binary>>),
    do: {{:ack_channel, ack_channel}, rest}

  def ime_from_binary(<<0x05, 0x01, transmit_channel, rest::binary>>),
    do: {{:transmit_channel, transmit_channel}, rest}

  def ime_from_binary(<<0x06, 0x01, routing_scheme, rest::binary>>),
    do: {{:routing_scheme, parse_routing_scheme(routing_scheme)}, rest}

  def ime_from_binary(<<0x07, 0x01, number_of_attempts, rest::binary>>),
    do: {{:routing_attempts, number_of_attempts}, rest}

  def ime_from_binary(<<0x08, 0x02, neighbor_node_id_1, neighbor_node_id_2, rest::binary>>),
    do: {{:failed_link, neighbor_node_id_1, neighbor_node_id_2}, rest}

  def ime_from_binary(
        <<0x09, 0x02, local_tx_power::signed, remote_tx_power::signed, rest::binary>>
      ) do
    {{:local_node_tx_power, parse_tx_power(local_tx_power), :remote_node_tx_power,
      parse_tx_power(remote_tx_power)}, rest}
  end

  def ime_from_binary(
        <<0x0A, 0x02, local_noise_floor::signed, remote_noise_floor::signed, rest::binary>>
      ) do
    {{:local_noise_floor, parse_noise_floor(local_noise_floor), :remote_noise_floor,
      parse_noise_floor(remote_noise_floor)}, rest}
  end

  def ime_from_binary(<<0x0B, 0x05, hop1, hop2, hop3, hop4, hop5, rest::binary>>) do
    {{:outgoing_rssi_hops,
      [
        parse_rssi_hop(hop1),
        parse_rssi_hop(hop2),
        parse_rssi_hop(hop3),
        parse_rssi_hop(hop4),
        parse_rssi_hop(hop5)
      ]}, rest}
  end

  defp parse_tx_power(0x7F), do: :not_available
  defp parse_tx_power(tx_power), do: tx_power

  defp parse_noise_floor(0x7F), do: :not_available
  defp parse_noise_floor(0x7E), do: :max_power_saturated
  defp parse_noise_floor(0x7D), do: :below_sensitivity
  defp parse_noise_floor(floor), do: floor

  defp parse_route_change_value(0x00), do: false
  defp parse_route_change_value(0x01), do: true

  defp parse_transmission_speed(0x01), do: {9.6, :kbit_sec}
  defp parse_transmission_speed(0x02), do: {40, :kbit_sec}
  defp parse_transmission_speed(0x03), do: {100, :kbit_sec}
  defp parse_transmission_speed(speed), do: {:unknown, speed}

  defp parse_rssi_hop(0x7F), do: :not_available
  defp parse_rssi_hop(0x7E), do: :max_power_saturated
  defp parse_rssi_hop(0x7D), do: :below_sensitivity
  defp parse_rssi_hop(n) when n <= -32 or n >= -94, do: n

  defp parse_routing_scheme(0x00), do: :idle
  defp parse_routing_scheme(0x01), do: :direct_transmission_no_routing
  defp parse_routing_scheme(0x02), do: :application_static_route
  defp parse_routing_scheme(0x03), do: :last_working_route
  defp parse_routing_scheme(0x04), do: :next_to_last_working_route
  defp parse_routing_scheme(0x05), do: :return_route_or_controller_auto_route
  defp parse_routing_scheme(0x06), do: :direct_resort
  defp parse_routing_scheme(0x07), do: :explorer_frame
  defp parse_routing_scheme(byte), do: {:unknown, byte}
end
