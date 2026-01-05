defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelGet do
  @moduledoc """
  Command to request the currently configured Z-Wave Long Range Channel

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :zwave_long_range_channel_get,
      command_byte: 0x0D,
      command_class: NetworkManagementInstallationMaintenance
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_), do: {:ok, []}

  @impl Grizzly.ZWave.Command
  def encode_params(_), do: <<>>
end
