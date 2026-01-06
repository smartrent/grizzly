defmodule Grizzly.ZWave.Commands.AssociationGroupInfoReport do
  @moduledoc """
  This command is used to advertise the properties of one or more association
  groups.

  Params:

    * `:dynamic` - whether the group info is subject to be changed by the device
    * `:groups_info` - a list of group info
    * `:list_mode` - a boolean if the report should be in list mode. In some
      cases this needs to be forced, like if you are reporting one group but the
      get query requested list mode. If you are reporting more than one group
      then this parameter is optional as it will know that more than one group
      can only be reported with list mode `true`. If you don't set this option
      to `true` when reporting one group then this will default to `false`.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.AssociationGroupInfo
  alias Grizzly.ZWave.DecodeError

  @type group_info() :: [group_id: byte(), profile: atom()]
  @type param() ::
          {:groups_info, [group_info()]} | {:dynamic, boolean() | {:list_mode, boolean()}}

  @impl Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_group_info_report,
      command_byte: 0x04,
      command_class: AssociationGroupInfo,
      params: params
    }

    {:ok, command}
  end

  @impl Command
  def encode_params(command) do
    list_mode = get_list_mode(command)
    dynamic? = Command.param!(command, :dynamic)
    dynamic_bit = if dynamic?, do: 0x01, else: 0x00
    groups_info = Command.param!(command, :groups_info)
    group_count = Enum.count(groups_info)

    encoded_groups_info =
      for group_info <- groups_info, into: <<>> do
        group_id = Keyword.fetch!(group_info, :group_id)
        profile = Keyword.fetch!(group_info, :profile)
        <<group_id, 0x00>> <> encode_profile(Atom.to_string(profile)) <> <<0x00, 0x00, 0x00>>
      end

    <<list_mode::1, dynamic_bit::1, group_count::6>> <> encoded_groups_info
  end

  @impl Command
  def decode_params(<<list_mode::1, dynamic_bit::1, group_count::6, encoded_groups_info::binary>>) do
    dynamic? = dynamic_bit == 0x01
    list_mode? = list_mode == 0x01

    case decode_groups_info(group_count, encoded_groups_info) do
      {:ok, groups_info} ->
        {:ok, [dynamic: dynamic?, groups_info: groups_info, list_mode: list_mode?]}

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
              <<group_id, 0x00, profile_msb, profile_lsb, _reserved, _event_code::16>> ->
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

  defp get_list_mode(command) do
    if Command.param(command, :list_mode, false) do
      0x01
    else
      groups_info = Command.param!(command, :groups_info)

      if length(groups_info) > 1, do: 0x01, else: 0x00
    end
  end
end
