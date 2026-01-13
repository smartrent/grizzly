defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.FirmwareUpdateMDReport

  test "creates the command and validates params" do
    {:ok, command} =
      Commands.create(:firmware_update_md_report,
        last?: false,
        report_number: 2,
        data: <<0x01, 0x02, 0x03>>
      )

    assert Command.param!(command, :last?) == false
    assert Command.param!(command, :report_number) == 2
    assert Command.param!(command, :data) == <<0x01, 0x02, 0x03>>
  end

  test "encodes params correctly" do
    {:ok, command} =
      Commands.create(:firmware_update_md_report,
        last?: false,
        report_number: 2,
        data: <<0x01, 0x02, 0x03>>
      )

    data = Command.param!(command, :data)
    expected_params_binary = <<0x00::1, 0x02::15, data::binary>>
    assert FirmwareUpdateMDReport.encode_params(nil, command) == expected_params_binary
  end

  test "decodes params correctly" do
    params_binary = <<0x01::1, 0x02::15, 0x01, 0x02, 0x03>>

    {:ok, params} = FirmwareUpdateMDReport.decode_params(nil, params_binary)
    assert Keyword.get(params, :last?) == true
    assert Keyword.get(params, :report_number) == 2
    assert Keyword.get(params, :data) == <<0x01, 0x02, 0x03>>
  end
end
