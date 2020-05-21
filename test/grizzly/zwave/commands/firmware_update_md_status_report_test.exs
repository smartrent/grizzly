defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDStatusReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FirmwareUpdateMDStatusReport
  alias Grizzly.ZWave.Command

  test "creates the command and validates params" do
    {:ok, command} =
      FirmwareUpdateMDStatusReport.new(status: :successful_restarting, wait_time: 10)

    assert Command.param!(command, :status) == :successful_restarting
    assert Command.param!(command, :wait_time) == 10
  end

  test "encodes params correctly" do
    {:ok, command} =
      FirmwareUpdateMDStatusReport.new(status: :successful_restarting, wait_time: 10)

    expected_params_binary = <<0xFF, 0x00, 0x0A>>
    assert expected_params_binary == FirmwareUpdateMDStatusReport.encode_params(command)
  end

  test "decodes params correctly" do
    encoded_params = <<0xFF, 0x00, 0x0A>>
    {:ok, params} = FirmwareUpdateMDStatusReport.decode_params(encoded_params)
    assert Keyword.get(params, :status) == :successful_restarting
    assert Keyword.get(params, :wait_time) == 10
  end
end
