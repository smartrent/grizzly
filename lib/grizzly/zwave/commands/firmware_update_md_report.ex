defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDReport do
  @moduledoc """
  The Firmware Update Meta Data Report Command is used to transfer a firmware image fragment.

  Params:

    * `:last?` - whether this report carries the last firmware image fragment. (required)

    * `:report_number` - indicates the sequence number of the contained firmware fragment (required)

    * `:data` - one firmware image fragment (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.FirmwareUpdateMD

  @type param :: {:last?, boolean} | {:report_number, non_neg_integer} | {:data, binary}

  @impl true
  def new(params) do
    command = %Command{
      name: :firmware_update_md_report,
      command_byte: 0x06,
      command_class: FirmwareUpdateMD,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    last_byte = encode_last(Command.param!(command, :last?))
    report_number = Command.param!(command, :report_number)
    data = Command.param!(command, :data)
    <<last_byte::size(1), report_number::size(15)-integer-unsigned, data::binary>>
  end

  @impl true
  def decode_params(
        <<last_byte::size(1), report_number::size(15)-integer-unsigned, data::binary>>
      ) do
    {:ok, last?} = decode_last(last_byte)
    {:ok, [last?: last?, report_number: report_number, data: data]}
  end

  defp encode_last(true), do: 0x01
  defp encode_last(false), do: 0x00

  defp decode_last(0x01), do: {:ok, true}
  defp decode_last(0x00), do: {:ok, false}
end
