defmodule Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance do
  @moduledoc """
  "NetworkManagementInstallationMaintenance" Command Class

  The Network Management Installation and Maintenance Command Class is used to access statistical
  data.
  """

  import Bitwise

  alias Grizzly.ZWave.DecodeError

  @type route_type ::
          :no_route | :last_working_route | :next_to_last_working_route | :set_by_application
  @type speeds :: [speed()]
  @type speed :: :"9.6kbit/s" | :"40kbit/s" | :"100kbit/s" | :reserved
  @type statistics :: [statistic]
  @type statistic ::
          {:route_changes, byte}
          | {:transmission_count, byte}
          | {:neighbors, [neighbor]}
          | {:packet_error_count, byte}
          | {:sum_of_transmission_times, non_neg_integer}
          | {:sum_of_transmission_times_squared, non_neg_integer}
  @type neighbor :: [neighbor_param]
  @type neighbor_param ::
          {:node_id, byte}
          | {:repeater?, boolean}
          | {:speed, speeds}
  @type rssi ::
          :rssi_not_available | :rssi_max_power_saturated | :rssi_below_sensitivity | -124..127

  @spec route_type_to_byte(route_type) :: byte
  def route_type_to_byte(type) do
    case type do
      :no_route -> 0x00
      :last_working_route -> 0x01
      :next_to_last_working_route -> 0x02
      :set_by_application -> 0x10
    end
  end

  @spec route_type_from_byte(any) :: {:error, Grizzly.ZWave.DecodeError.t()} | {:ok, route_type}
  def route_type_from_byte(byte) do
    case byte do
      0x00 -> {:ok, :no_route}
      0x01 -> {:ok, :last_working_route}
      0x02 -> {:ok, :next_to_last_working_route}
      0x10 -> {:ok, :set_by_application}
      byte -> {:error, %DecodeError{param: :type, value: byte}}
    end
  end

  @spec speed_to_byte(speed()) :: byte()
  def speed_to_byte(speed) do
    case speed do
      :"9.6kbit/s" -> 0x01
      :"40kbit/s" -> 0x02
      :"100kbit/s" -> 0x03
    end
  end

  @spec speed_from_byte(byte()) :: {:ok, speed()} | {:error, DecodeError.t()}
  def speed_from_byte(byte) do
    case byte do
      0x00 -> {:ok, :unknown}
      0x01 -> {:ok, :"9.6kbit/s"}
      0x02 -> {:ok, :"40kbit/s"}
      0x03 -> {:ok, :"100kbit/s"}
      byte -> {:error, %DecodeError{param: :speed, value: byte}}
    end
  end

  @spec neighbor_speeds_to_byte(speeds()) :: byte()
  def neighbor_speeds_to_byte(speeds) do
    byte = if :"9.6kbit/s" in speeds, do: 0x01, else: 0x00
    byte = if :"40kbit/s" in speeds, do: byte ||| 0x02, else: byte
    if :"100kbit/s" in speeds, do: byte ||| 0x04, else: byte
  end

  @spec neighbor_speeds_from_byte(byte) :: {:ok, speeds}
  def neighbor_speeds_from_byte(byte) do
    case byte do
      0x01 -> {:ok, [:"9.6kbit/s"]}
      0x02 -> {:ok, [:"40kbit/s"]}
      0x03 -> {:ok, [:"9.6kbit/s", :"40kbit/s"]}
      0x04 -> {:ok, [:"100kbit/s"]}
      0x05 -> {:ok, [:"9.6kbit/s", :"100kbit/s"]}
      0x06 -> {:ok, [:"40kbit/s", :"100kbit/s"]}
      0x07 -> {:ok, [:"9.6kbit/s", :"40kbit/s", :"100kbit/s"]}
      _other -> {:ok, []}
    end
  end

  @doc """
  Encodes the given RSSI value to an 8-bit signed integer.

  **NOTE:** In order to support Z/IP Gateway quirks, this function accepts values
  outside of the range specified in the spec (-32..-128). Values out of range for
  an 8-bit signed integer will overflow.
  """
  @spec rssi_to_byte(rssi()) :: byte()
  def rssi_to_byte(:rssi_below_sensitivity), do: 0x7D
  def rssi_to_byte(:rssi_max_power_saturated), do: 0x7E
  def rssi_to_byte(:rssi_not_available), do: 0x7F

  def rssi_to_byte(rssi) do
    <<byte::8>> = <<rssi::signed>>
    byte
  end

  @doc """
  Decodes the given byte to an 8-bit signed integer (or one of the special values
  defined in the spec).

  **NOTE:** In order to support Z/IP Gateway quirks, this function accepts values
  outside of the range specified in the spec (-32..-128). This function may return
  any value in the range -128..124.
  """
  @spec rssi_from_byte(byte()) :: rssi()
  def rssi_from_byte(0x7D), do: :rssi_below_sensitivity
  def rssi_from_byte(0x7E), do: :rssi_max_power_saturated
  def rssi_from_byte(0x7F), do: :rssi_not_available

  def rssi_from_byte(byte) do
    <<rssi::signed>> = <<byte::8>>
    rssi
  end

  def repeaters_to_bytes(repeaters) do
    full_repeaters = (repeaters ++ [0, 0, 0, 0]) |> Enum.take(4)
    for repeater <- full_repeaters, into: <<>>, do: <<repeater>>
  end

  def repeaters_from_bytes(bytes) do
    :erlang.binary_to_list(bytes)
    |> Enum.reject(&(&1 == 0))
  end

  def statistics_to_binary(statistics) do
    for statistic <- statistics, into: <<>> do
      case statistic do
        {:route_changes, byte} ->
          <<0x00, 0x01, byte>>

        {:transmission_count, byte} ->
          <<0x01, 0x01, byte>>

        {:neighbors, neighbors} ->
          binary = neighbors_to_binary(neighbors)
          <<0x02, byte_size(binary)>> <> binary

        {:packet_error_count, byte} ->
          <<0x03, 0x01, byte>>

        {:sum_of_transmission_times, sum} ->
          <<0x04, 0x04, sum::32>>

        {:sum_of_transmission_times_squared, sum} ->
          <<0x05, 0x04, sum::32>>
      end
    end
  end

  def statistics_from_binary(<<>>) do
    {:ok, []}
  end

  def statistics_from_binary(<<0x00, 0x01, byte, rest::binary>>) do
    with {:ok, other_statistics} <- statistics_from_binary(rest) do
      {:ok, [route_changes: byte] ++ other_statistics}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def statistics_from_binary(<<0x01, 0x01, byte, rest::binary>>) do
    with {:ok, other_statistics} <- statistics_from_binary(rest) do
      {:ok, [transmission_count: byte] ++ other_statistics}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def statistics_from_binary(
        <<0x02, length, neighbors_binary::binary-size(length), rest::binary>>
      ) do
    with {:ok, other_statistics} <- statistics_from_binary(rest),
         {:ok, neighbors} <- neighbors_from_binary(neighbors_binary) do
      {:ok, [neighbors: neighbors] ++ other_statistics}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def statistics_from_binary(<<0x03, 0x01, byte, rest::binary>>) do
    with {:ok, other_statistics} <- statistics_from_binary(rest) do
      {:ok, [packet_error_count: byte] ++ other_statistics}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def statistics_from_binary(<<0x04, 0x04, sum::32, rest::binary>>) do
    with {:ok, other_statistics} <- statistics_from_binary(rest) do
      {:ok, [sum_of_transmission_times: sum] ++ other_statistics}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  def statistics_from_binary(<<0x05, 0x04, sum::32, rest::binary>>) do
    with {:ok, other_statistics} <- statistics_from_binary(rest) do
      {:ok, [sum_of_transmission_times_squared: sum] ++ other_statistics}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp neighbors_to_binary(neighbors) do
    for neighbor <- neighbors, into: <<>>, do: neighbor_to_binary(neighbor)
  end

  defp neighbor_to_binary(neighbor) do
    node_id = Keyword.get(neighbor, :node_id)
    repeater_bit = if Keyword.get(neighbor, :repeater?), do: 0x01, else: 0x00
    speeds_bits = Keyword.get(neighbor, :speed) |> neighbor_speeds_to_byte()
    <<node_id, repeater_bit::1, 0x00::2, speeds_bits::5>>
  end

  defp neighbors_from_binary(<<>>), do: {:ok, []}

  defp neighbors_from_binary(
         <<node_id, repeater_bit::1, _reserved::2, speeds_bits::5, rest::binary>>
       ) do
    with {:ok, speeds} <- neighbor_speeds_from_byte(speeds_bits),
         {:ok, other_neighbors} <- neighbors_from_binary(rest) do
      neighbor = [node_id: node_id, repeater?: repeater_bit == 1, speed: speeds]
      {:ok, [neighbor | other_neighbors]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
