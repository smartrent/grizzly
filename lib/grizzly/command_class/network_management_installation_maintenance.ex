defmodule Grizzly.CommandClass.NetworkManagementInstallationMaintenance do
  @type priority_route_report :: %{
          node_id: non_neg_integer,
          repeaters: [non_neg_integer],
          type: route_type,
          speed: speed
        }

  @type speed :: :"9.6 kbit/sec" | :"40 kbit/sec" | :"100 kbit/sec" | :unknown
  @type route_type ::
          :no_route
          | :last_working_route
          | :next_to_last_working_route
          | :determined_by_application

  @type statistics_report :: map

  @type rssi_report :: [rssi_value]
  @type rssi_value ::
          :not_available | :max_power_saturated | :below_sensitivity | :above_sensitivity

  def decode_speed(0x01), do: :"9.6 kbit/sec"
  def decode_speed(0x02), do: :"40 kbit/sec"
  def decode_speed(0x03), do: :"100 kbit/sec"
  def decode_speed(_), do: :unknown

  def decode_route_type(0x00), do: :no_route
  def decode_route_type(0x01), do: :last_working_route
  def decode_route_type(0x02), do: :next_to_last_working_route
  def decode_route_type(0x10), do: :determined_by_application

  def decode_statistics(<<>>) do
    %{}
  end

  def decode_statistics(
        <<type::size(8), length::size(8), value::binary-size(length), rest::binary()>>
      ) do
    stat_type = decode_stat_type(type)
    stat_value = decode_stat_value(stat_type, value)
    Map.new([{stat_type, stat_value}]) |> Map.merge(decode_statistics(rest))
  end

  # :not_available | :max_power_saturated | :below_sensitivity
  def decode_rssi_value(0x7F), do: :not_available
  def decode_rssi_value(0x7E), do: :max_power_saturated
  def decode_rssi_value(0x7D), do: :below_sensitivity
  def decode_rssi_value(_), do: :above_sensitivity

  defp decode_stat_type(0x00), do: :route_changes
  defp decode_stat_type(0x01), do: :transmission_count
  defp decode_stat_type(0x02), do: :neighbors
  defp decode_stat_type(0x03), do: :packet_error_count
  defp decode_stat_type(0x04), do: :transmission_times_average
  defp decode_stat_type(0x05), do: :transmission_times_variance

  defp decode_stat_value(:route_changes, <<n::size(8)>>), do: n
  defp decode_stat_value(:transmission_count, <<n::size(8)>>), do: n
  defp decode_stat_value(:packet_error_count, <<n::size(8)>>), do: n

  defp decode_stat_value(:neighbors, <<>>) do
    []
  end

  defp decode_stat_value(
         :neighbors,
         <<node_id::size(8), repeater_bit::size(1), _reserved::size(2), speed::size(5),
           rest::binary>>
       ) do
    repeater? = repeater_bit == 0x01
    stat = %{node_id: node_id, repeater: repeater?, speed: decode_speed(speed)}
    [stat | decode_stat_value(:neighbors, rest)]
  end

  defp decode_stat_value(
         :transmission_times_average,
         <<t1::size(8), t2::size(8), t3::size(8), t4::size(8)>>
       ) do
    Enum.sum([t1, t2, t3, t4]) / 4
  end

  defp decode_stat_value(
         :transmission_times_variance,
         <<ts1::size(8), ts2::size(8), ts3::size(8), ts4::size(8)>>
       ) do
    Enum.sum([ts1, ts2, ts3, ts4]) / 4
  end
end
