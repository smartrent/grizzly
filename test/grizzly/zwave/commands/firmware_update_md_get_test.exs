defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FirmwareUpdateMDGet
  alias Grizzly.ZWave.Command

  test "creates the command and validates params" do
    {:ok, command} = FirmwareUpdateMDGet.new(number_of_reports: 2, report_number: 1)
    assert Command.param!(command, :number_of_reports) == 2
    assert Command.param!(command, :report_number) == 1
  end

  test "encodes params correctly" do
    {:ok, command} = FirmwareUpdateMDGet.new(number_of_reports: 2, report_number: 1)
    number_of_reports = Command.param!(command, :number_of_reports)
    report_number = Command.param!(command, :report_number)

    expected_params_binary =
      <<number_of_reports, 0x00::size(1), report_number::size(15)-integer-unsigned>>

    assert expected_params_binary == FirmwareUpdateMDGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<2, 0x00::size(1), 10::size(15)-integer-unsigned>>
    {:ok, params} = FirmwareUpdateMDGet.decode_params(params_binary)
    assert Keyword.get(params, :number_of_reports) == 2
    assert Keyword.get(params, :report_number) == 10
  end
end
