defmodule Grizzly.ZWave.Commands.FirmwareUpdateActivationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.FirmwareUpdateActivationReport

  test "creates the command and validates params" do
    {:ok, command} =
      FirmwareUpdateActivationReport.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        status: :success,
        hardware_version: 4
      )

    assert Command.param!(command, :manufacturer_id) == 1
    assert Command.param!(command, :firmware_id) == 2
    assert Command.param!(command, :checksum) == 3
    assert Command.param!(command, :firmware_target) == 0
    assert Command.param!(command, :status) == :success
    assert Command.param!(command, :hardware_version) == 4
  end

  test "encodes params correctly - v1" do
    {:ok, command} =
      FirmwareUpdateActivationReport.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        status: :success
      )

    expected_param_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0xFF>>

    assert expected_param_binary == FirmwareUpdateActivationReport.encode_params(command)
  end

  test "decodes params correctly -v5" do
    {:ok, command} =
      FirmwareUpdateActivationReport.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        status: :success,
        hardware_version: 4
      )

    expected_param_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0xFF, 0x04>>

    assert expected_param_binary == FirmwareUpdateActivationReport.encode_params(command)
  end
end
