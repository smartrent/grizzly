defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDReport do
  @moduledoc """
  The Firmware Update Meta Data Report Command is used to transfer a firmware image fragment.

  Params:

    * `:last?` - whether this report carries the last firmware image fragment. (required)

    * `:report_number` - indicates the sequence number of the contained firmware fragment (required)

    * `:data` - one firmware image fragment (required)

    * `:checksum` - the checksum for the entire command (minus the checksum bytes) (v3 - optional)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:last?, boolean} | {:report_number, non_neg_integer} | {:data, binary}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    last_byte = encode_last(Command.param!(command, :last?))
    report_number = Command.param!(command, :report_number)
    data = Command.param!(command, :data)
    binary_params = <<last_byte::1, report_number::15, data::binary>>
    checksum = Command.param(command, :checksum)

    if checksum == nil do
      binary_params
    else
      binary_params <> <<checksum::16>>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<last_byte::1, report_number::15, data::binary>>) do
    # The last 2 bytes of data MAY be a checksum
    {:ok, last?} = decode_last(last_byte)
    {:ok, [last?: last?, report_number: report_number, data: data]}
  end

  defp encode_last(true), do: 0x01
  defp encode_last(false), do: 0x00

  defp decode_last(0x01), do: {:ok, true}
  defp decode_last(0x00), do: {:ok, false}
end
