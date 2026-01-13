defmodule Grizzly.ZWave.Commands.ZWaveLongRangeChannelReport do
  @moduledoc """
  Command to advertise the configured Z-Wave Long Range Channel

  Params:

  * `:channel` - which channel that is used for Z-Wave long range
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @typedoc """
  The long range channel
  """
  @type long_range_channel() :: :primary | :secondary

  @typedoc """
  Parameters to the command
  """
  @type param() :: {:channel, long_range_channel()}

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<0x01>>), do: {:ok, [channel: :primary]}
  def decode_params(_spec, <<0x02>>), do: {:ok, [channel: :secondary]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    case Command.param!(command, :channel) do
      :primary -> <<0x01>>
      :secondary -> <<0x02>>
    end
  end
end
