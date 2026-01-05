defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelSet do
  @moduledoc """
  Command to configure which channel to use for Z-Wave Long Range

  Params:
  * `:channel` - which channel that is used for Z-Wave long range
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  @typedoc """
  The long range channel
  """
  @type long_range_channel() :: :primary | :secondary

  @typedoc """
  Parameters to the command
  """
  @type param() :: {:channel, long_range_channel()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :zwave_long_range_channel_set,
      command_byte: 0x0A,
      command_class: NetworkManagementInstallationMaintenance,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<0x01>>), do: {:ok, [channel: :primary]}
  def decode_params(<<0x02>>), do: {:ok, [channel: :secondary]}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    case Command.param!(command, :channel) do
      :primary -> <<0x01>>
      :secondary -> <<0x02>>
    end
  end
end
