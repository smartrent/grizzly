defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FirmwareUpdateMDReport
  alias Grizzly.ZWave.Command

  test "creates the command and validates params" do
    {:ok, command} =
      FirmwareUpdateMDReport.new(last?: false, report_number: 2, data: <<0x01, 0x02, 0x03>>)

    assert Command.param!(command, :last?) == false
    assert Command.param!(command, :report_number) == 2
    assert Command.param!(command, :data) == <<0x01, 0x02, 0x03>>
  end

  test "encodes params correctly" do
    {:ok, command} =
      FirmwareUpdateMDReport.new(last?: false, report_number: 2, data: <<0x01, 0x02, 0x03>>)

    data = Command.param!(command, :data)
    expected_params_binary = <<0x00::1, 0x02::size(15)-integer-unsigned, data::binary>>
    assert FirmwareUpdateMDReport.encode_params(command) == expected_params_binary
  end

  test "decodes params correctly" do
    params_binary =
      <<0x01::1, 0x02::size(15)-integer-unsigned, <<0x01, 0x02, 0x03>>::binary>>

    {:ok, params} = FirmwareUpdateMDReport.decode_params(params_binary)
    assert Keyword.get(params, :last?) == true
    assert Keyword.get(params, :report_number) == 2
    assert Keyword.get(params, :data) == <<0x01, 0x02, 0x03>>
  end
end
