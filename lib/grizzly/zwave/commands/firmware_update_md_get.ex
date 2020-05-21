defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDGet do
  @moduledoc """
  The Firmware Update Meta Data Get Command is used to request one or more Firmware Update Meta
  Data Report Commands.

  Params:

    * `:number_of_reports` - Number of firmware update md reports to be received in response to this command (required)

    * `:report_number` - The requested report (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.FirmwareUpdateMD

  @type param :: {:number_of_reports, byte} | {:report_number, non_neg_integer}

  @impl true
  def new(params) do
    command = %Command{
      name: :firmware_update_md_get,
      command_byte: 0x05,
      command_class: FirmwareUpdateMD,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    number_of_reports = Command.param!(command, :number_of_reports)
    report_number = Command.param!(command, :report_number)
    <<number_of_reports, 0x00::size(1), report_number::size(15)-integer-unsigned>>
  end

  @impl true
  def decode_params(<<number_of_reports, _::size(1), report_number::size(15)-integer-unsigned>>) do
    {:ok, [number_of_reports: number_of_reports, report_number: report_number]}
  end
end
