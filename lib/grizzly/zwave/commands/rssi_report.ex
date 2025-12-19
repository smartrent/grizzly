defmodule Grizzly.ZWave.Commands.RssiReport do
  @moduledoc """
  This command is used to advertise the measured RSSI on the Z-Wave network for
  each used channel.

  Params:

    * `:channels` - Each carries the measured RSSI value for the channel
    * `:long_range_primary_channel`- RSSI value on the Z-Wave Long Range primary
      channel (optional, v4 only)
    * `:long_range_secondary_channel`- RSSI value on the Z-Wave Long Range
      secondary channel (optional, v4 only)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance
  alias Grizzly.ZWave.DecodeError

  @type param() ::
          {:channels, [NetworkManagementInstallationMaintenance.rssi()]}
          | {:long_range_primary_channel, NetworkManagementInstallationMaintenance.rssi()}
          | {:long_range_secondary_channel, NetworkManagementInstallationMaintenance.rssi()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :rssi_report,
      command_byte: 0x08,
      command_class: NetworkManagementInstallationMaintenance,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    channels = Command.param!(command, :channels)

    channels_bin =
      for channel <- channels,
          into: <<>>,
          do: <<NetworkManagementInstallationMaintenance.rssi_to_byte(channel)>>

    maybe_add_long_range_channels(command, channels_bin)
  end

  defp maybe_add_long_range_channels(command, params_bin) do
    case Command.param(command, :long_range_primary_channel) do
      nil ->
        params_bin

      primary_channel ->
        secondary_channel_byte =
          command
          |> Command.param!(:long_range_secondary_channel)
          |> NetworkManagementInstallationMaintenance.rssi_to_byte()

        primary_channel_byte =
          NetworkManagementInstallationMaintenance.rssi_to_byte(primary_channel)

        <<params_bin::binary, primary_channel_byte, secondary_channel_byte>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<channels::binary-size(3)>>) do
    {:ok, [channels: parse_channels(channels)]}
  end

  def decode_params(<<channels_bin::binary-size(3), lr_primary, lr_secondary>>) do
    channels = parse_channels(channels_bin)

    parsed_lr_primary = NetworkManagementInstallationMaintenance.rssi_from_byte(lr_primary)

    # if LR Primary and Secondary are both unavailable, Z/IP Gateway will (currently)
    # send 0x7F, 0x00 instead of the expected 0x7F, 0x7F.
    parsed_lr_secondary =
      case {parsed_lr_primary, lr_secondary} do
        {:rssi_not_available, 0} -> :rssi_not_available
        _ -> NetworkManagementInstallationMaintenance.rssi_from_byte(lr_secondary)
      end

    {:ok,
     [
       channels: channels,
       long_range_primary_channel: parsed_lr_primary,
       long_range_secondary_channel: parsed_lr_secondary
     ]}
  end

  defp parse_channels(<<channel_1, channel_2, channel_3>>) do
    Enum.map(
      [channel_1, channel_2, channel_3],
      &NetworkManagementInstallationMaintenance.rssi_from_byte/1
    )
  end
end
