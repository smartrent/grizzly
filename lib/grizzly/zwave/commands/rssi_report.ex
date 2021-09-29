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

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

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

    with {:ok, parsed_lr_primary} <-
           NetworkManagementInstallationMaintenance.rssi_from_byte(lr_primary),
         {:ok, parsed_lr_secondary} <-
           NetworkManagementInstallationMaintenance.rssi_from_byte(lr_secondary) do
      {:ok,
       [
         channels: channels,
         long_range_primary_channel: parsed_lr_primary,
         long_range_secondary_channel: parsed_lr_secondary
       ]}
    end
  end

  defp parse_channels(<<channel_1, channel_2, channel_3>>) do
    channel_bytes = [channel_1, channel_2, channel_3]

    channels =
      Enum.reduce_while(channel_bytes, [], fn channel_byte, acc ->
        case NetworkManagementInstallationMaintenance.rssi_from_byte(channel_byte) do
          {:ok, channel} ->
            {:cont, acc ++ [channel]}

          # All other values are reserved and MUST NOT be used by a sending node. Reserved values MUST be
          # ignored by a receiving node.
          {:error, %DecodeError{}} ->
            {:cont, acc}
        end
      end)

    channels
  end
end
