defmodule Grizzly.CommandClass.AssociationGroupInfo do
  alias Grizzly.CommandClass.Mappings
  require Logger

  @type group_name_report :: %{group: non_neg_integer, name: String.t()}
  @type groups_info_report :: %{groups_info: [group_info], dynamic: boolean}
  @type group_info :: %{group: non_neg_integer, profile: group_profile}
  @type group_profile :: atom
  @type group_command_list_report :: %{group: non_neg_integer, commands: [group_command]}
  @type group_command :: %{command_class: atom, command: atom}

  @spec decode_group_name(non_neg_integer, binary) :: String.t()
  def decode_group_name(length, binary) do
    _ =
      if byte_size(binary) != length do
        _ =
          Logger.warn(
            "Mismatch between name length (#{inspect(length)} and name (#{inspect(binary)})"
          )
      end

    binary
  end

  @spec decode_groups_info(non_neg_integer, binary) :: [group_info]
  def decode_groups_info(group_count, encoded_groups_info) do
    list = :erlang.binary_to_list(encoded_groups_info)
    chunks = Enum.chunk_every(list, 7)

    if Enum.count(chunks) != group_count do
      _ = Logger.warn("Unexpected number of groups info. Expected #{group_count}.")
      []
    else
      Enum.reduce_while(
        chunks,
        [],
        fn chunk, acc ->
          binary = :erlang.list_to_binary(chunk)

          case binary do
            <<
              group,
              0x00,
              profile_msb,
              profile_lsb,
              _reserved,
              _event_code::size(16)
            >> ->
              {:cont, [%{group: group, profile: encode_profile(profile_msb, profile_lsb)} | acc]}

            other ->
              _ = Logger.warn("Invalid group info #{inspect(other)} ")
              {:halt, []}
          end
        end
      )
      |> Enum.reverse()
    end
  end

  @spec decode_group_command_list(non_neg_integer, binary) :: [group_command]
  def decode_group_command_list(list_length, encoded_command_list) do
    byte_list = :erlang.binary_to_list(encoded_command_list)

    _ =
      if Enum.count(byte_list) != list_length do
        _ =
          Logger.warn(
            "Unexpected number of bytes in encoded command list. Expected #{list_length}, got #{
              Enum.count(byte_list)
            }"
          )
      end

    {_, group_command_list} =
      Enum.reduce(
        byte_list,
        {[], []},
        fn byte, {buffer, acc} ->
          updated_buffer = buffer ++ [byte]

          case specified_command(updated_buffer) do
            nil ->
              {updated_buffer, acc}

            {command_class, command} ->
              {[], [%{command_class: command_class, command: command} | acc]}
          end
        end
      )

    group_command_list |> Enum.reverse()
  end

  defp encode_profile(0x00, 0x00), do: :general_na
  defp encode_profile(0x00, 0x01), do: :general_lifeline
  defp encode_profile(0x20, key), do: :"control_key_#{key}"
  defp encode_profile(0x31, 0x01), do: :sensor_air_temperature
  defp encode_profile(0x31, 0x05), do: :sensor_humidity
  defp encode_profile(0x71, 0x01), do: :notification_smoke_alarm
  defp encode_profile(0x71, 0x03), do: :notification_co2_alarm
  defp encode_profile(0x71, _), do: :notification_unknown
  defp encode_profile(0x32, 0x01), do: :meter_electric_kwh
  defp encode_profile(0x32, 0x02), do: :meter_gas
  defp encode_profile(0x32, 0x03), do: :meter_water
  defp encode_profile(0x32, _), do: :meter_unknown
  defp encode_profile(0x6B, key), do: :"irrigation_channel_#{key}"
  defp encode_profile(_profile_msb, _profile_lsb), do: :unknown

  defp specified_command([_]), do: nil
  defp specified_command([cc_byte, _]) when cc_byte in [0xF1..0xFF], do: nil

  defp specified_command([cc_byte1, cc_byte2, c_byte]) when cc_byte1 in [0xF1..0xFF] do
    _ =
      Logger.warn(
        "Ignoring command #{c_byte} from extended command class #{cc_byte1}, #{cc_byte2}"
      )

    {:unknown, :unknown}
  end

  defp specified_command([cc_byte, c_byte]) do
    command_class =
      case Mappings.from_byte(cc_byte) do
        {:unk, _} ->
          _ = Logger.warn("Unmapped command class #{cc_byte}")
          :"#{Integer.to_string(cc_byte, 16)}"

        name ->
          name
      end

    command =
      case Mappings.command_from_byte(cc_byte, c_byte) do
        {:unk, _} ->
          _ = Logger.warn("Unmapped class #{c_byte} of command class #{inspect(command_class)}")
          :"#{Integer.to_string(c_byte, 16)}"

        name ->
          name
      end

    {command_class, command}
  end

  defp specified_command(_), do: {:unknown, :unknown}
end
