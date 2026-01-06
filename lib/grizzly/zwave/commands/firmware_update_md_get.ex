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

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :firmware_update_md_get,
      command_byte: 0x05,
      command_class: FirmwareUpdateMD,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    number_of_reports = Command.param!(command, :number_of_reports)
    report_number = Command.param!(command, :report_number)
    <<number_of_reports, 0x00::1, report_number::15>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<number_of_reports, _::1, report_number::15>>) do
    {:ok, [number_of_reports: number_of_reports, report_number: report_number]}
  end
end
