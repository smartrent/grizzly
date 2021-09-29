defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelReport do
  @moduledoc """
  Command to advertise the configured Z-Wave Long Range Channel

  Params:

  * `:channel` - which channel that is used for Z-Wave long range
  """

  @typedoc """
  The long range channel
  """
  @type long_range_channel() :: :primary | :secondary

  @typedoc """
  Parameters to the command
  """
  @type param() :: {:channel, long_range_channel()}

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :zwave_long_range_channel_report,
      command_byte: 0x0E,
      command_class: NetworkManagementInstallationMaintenance,
      impl: __MODULE__,
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
