defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReport

  test "creates the command and validates params" do
    {:ok, command} =
      Commands.create(:firmware_update_md_request_report, status: :insufficient_battery_level)

    assert Command.param!(command, :status) == :insufficient_battery_level
  end

  test "encodes params correctly" do
    {:ok, command} = Commands.create(:firmware_update_md_request_report, status: :ok)
    expected_param_binary = <<0xFF>>
    assert expected_param_binary == FirmwareUpdateMDRequestReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<0xFF>>
    {:ok, params} = FirmwareUpdateMDRequestReport.decode_params(nil, params_binary)
    assert Keyword.get(params, :status) == :ok
  end
end
