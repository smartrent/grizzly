defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReport
  alias Grizzly.ZWave.Command

  test "creates the command and validates params" do
    {:ok, command} = FirmwareUpdateMDRequestReport.new(status: :insufficient_battery_level)

    assert Command.param!(command, :status) == :insufficient_battery_level
  end

  test "encodes params correctly" do
    {:ok, command} = FirmwareUpdateMDRequestReport.new(status: :ok)
    expected_param_binary = <<FirmwareUpdateMDRequestReport.encode_status(:ok)>>
    assert expected_param_binary == FirmwareUpdateMDRequestReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0xFF>>
    {:ok, params} = FirmwareUpdateMDRequestReport.decode_params(params_binary)
    assert Keyword.get(params, :status) == :ok
  end
end
