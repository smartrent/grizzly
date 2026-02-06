defmodule Grizzly.ZWave do
  @moduledoc """
  Module for Z-Wave protocol specific functionality and information
  """

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.DecodeError

  @type seq_number :: non_neg_integer()

  @type node_id :: non_neg_integer()
  @type endpoint_id :: 0..127

  @typedoc """
  The volume at which a tone is played.

  ## Values

  * `0` - Indicates an off/mute volume setting.
  * `1..100` - Indicates the actual volume setting from 1% to 100%.
  * `255` - Restore the most recent non-zero volume setting. This value MUST be
    ignored if the current volume is not zero. This value MAY be used to set the
    default tone without modifying the volume setting.
  """
  @type sound_switch_volume :: 0..100 | 255

  @spec from_binary(binary()) :: {:ok, Command.t()} | {:error, DecodeError.t()}
  def from_binary(binary) do
    Logger.metadata(zwave_command: inspect(binary, base: :hex, limit: 100))

    Commands.decode(binary)
  end

  @spec to_binary(Command.t()) :: nonempty_binary()
  def to_binary(command) do
    Command.to_binary(command)
  end

  @crc16_aug_ccitt :cerlc.init(:crc16_aug_ccitt)

  @doc """
  CRC-16/AUG-CCITT
  """
  @spec crc16_aug_ccitt(binary() | [byte()]) :: 0..0xFFFF
  def crc16_aug_ccitt(data) do
    :cerlc.calc_crc(data, @crc16_aug_ccitt)
  end
end
