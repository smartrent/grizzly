defmodule Grizzly.ZWave.Commands.AssociationGroupInfoReport do
  @moduledoc """
  This command is used to advertise the properties of one or more association groups.

  Params:

    * `:dynamic` - whether the group info is subject to be changed by the device
    * `:groups_info` - a list of group info

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.AssociationGroupInfo

  @type group_info :: [group_id: byte, profile: atom]
  @type param :: {:groups_info, [group_info]} | {:dynamic, boolean}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_group_info_report,
      command_byte: 0x04,
      command_class: AssociationGroupInfo,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    dynamic? = Command.param!(command, :dynamic)
    dynamic_bit = if dynamic?, do: 0x01, else: 0x00
    groups_info = Command.param!(command, :groups_info)
    group_count = Enum.count(groups_info)
    list_mode_bit = if group_count == 1, do: 0x00, else: 0x01

    encoded_groups_info =
      for group_info <- groups_info, into: <<>> do
        group_id = Keyword.fetch!(group_info, :group_id)
        profile = Keyword.fetch!(group_info, :profile)
        <<group_id, 0x00>> <> encode_profile(Atom.to_string(profile)) <> <<0x00, 0x00, 0x00>>
      end

    <<list_mode_bit::size(1), dynamic_bit::size(1), group_count::size(6)>> <> encoded_groups_info
  end

  @impl true
  def decode_params(
        <<_list_mode::size(1), dynamic_bit::size(1), group_count::size(6),
          encoded_groups_info::binary>>
      ) do
    dynamic? = dynamic_bit == 0x01

    case decode_groups_info(group_count, encoded_groups_info) do
      {:ok, groups_info} ->
        {:ok, [dynamic: dynamic?, groups_info: groups_info]}

      {:error, %DecodeError{} = error} ->
        error
    end
  end

  defp decode_groups_info(group_count, encoded_groups_info) do
    list = :erlang.binary_to_list(encoded_groups_info)
    chunks = Enum.chunk_every(list, 7)

    if Enum.count(chunks) != group_count do
      %DecodeError{}
    else
      result =
        Enum.reduce_while(
          chunks,
          [],
          fn chunk, acc ->
            binary = :erlang.list_to_binary(chunk)

            case binary do
              <<
                group_id,
                0x00,
                profile_msb,
                profile_lsb,
                _reserved,
                _event_code::size(16)
              >> ->
                profile = decode_profile(profile_msb, profile_lsb)
                {:cont, [[group_id: group_id, profile: profile] | acc]}

              _other ->
                {:halt,
                 {:error,
                  %DecodeError{
                    value: binary,
                    param: :groups_info,
                    command: :association_group_info_report
                  }}}
            end
          end
        )

      case result do
        {:error, error} -> {:error, error}
        _groups_info -> {:ok, Enum.reverse(result)}
      end
    end
  end

  defp decode_profile(0x00, 0x00), do: :general_na
  defp decode_profile(0x00, 0x01), do: :general_lifeline
  defp decode_profile(0x20, key), do: :"control_key_#{key}"
  defp decode_profile(0x31, 0x01), do: :sensor_air_temperature
  defp decode_profile(0x31, 0x05), do: :sensor_humidity
  defp decode_profile(0x71, 0x01), do: :notification_smoke_alarm
  defp decode_profile(0x71, 0x03), do: :notification_co2_alarm
  defp decode_profile(0x71, _), do: :notification_unknown
  defp decode_profile(0x32, 0x01), do: :meter_electric_kwh
  defp decode_profile(0x32, 0x02), do: :meter_gas
  defp decode_profile(0x32, 0x03), do: :meter_water
  defp decode_profile(0x32, _), do: :meter_unknown
  defp decode_profile(0x6B, key), do: :"irrigation_channel_#{key}"
  defp decode_profile(_profile_msb, _profile_lsb), do: :unknown

  defp encode_profile("general_na"), do: <<0x00, 0x00>>
  defp encode_profile("general_lifeline"), do: <<0x00, 0x01>>
  defp encode_profile(<<"control_key_", key::binary>>), do: <<0x20, elem(Integer.parse(key), 0)>>
  defp encode_profile("sensor_air_temperature"), do: <<0x31, 0x01>>
  defp encode_profile("sensor_humidity"), do: <<0x31, 0x05>>
  defp encode_profile("notification_smoke_alarm"), do: <<0x71, 0x01>>
  defp encode_profile("notification_co2_alarm"), do: <<0x71, 0x03>>
  defp encode_profile("notification_unknown"), do: <<0x71, 0x00>>
  defp encode_profile("meter_electric_kwh"), do: <<0x32, 0x01>>
  defp encode_profile("meter_gas"), do: <<0x32, 0x02>>
  defp encode_profile("meter_water"), do: <<0x32, 0x03>>
  defp encode_profile("meter_unknown"), do: <<0x32, 0x00>>

  defp encode_profile(<<"irrigation_channel_", key::binary>>),
    do: <<0x6B, elem(Integer.parse(key), 0)>>
end
