defmodule Grizzly.FirmwareUpdates.FirmwareUpdateRunnerTest do
  use ExUnit.Case, async: true

  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner
  # alias Grizzly.ZWave.Command

  @tag :firmware_update
  test "request that a device begin a firmware update" do
    image_path = "test/serialapi_controller_bridge_OTW_SD3503_US.gbl"

    {:ok, runner} =
      FirmwareUpdateRunner.start_link(
        # test server will ack and send report response
        device_id: 300,
        manufacturer_id: 1
      )

    :ok = FirmwareUpdateRunner.start_firmware_update(runner, image_path)
    assert_receive {:grizzly, :report, received_command}, 500
    assert received_command.name == :firmware_update_md_request_report
  end

  test "request that a device updates its firmware" do
    image_path = "test/serialapi_controller_bridge_OTW_SD3503_US.gbl"

    {:ok, runner} =
      FirmwareUpdateRunner.start_link(
        # test server will ack and send report response
        device_id: 201,
        manufacturer_id: 1
      )

    :ok = FirmwareUpdateRunner.start_firmware_update(runner, image_path)
    assert_receive {:grizzly, :report, received_command}, 500
    assert received_command.name == :firmware_update_md_request_report
    :timer.sleep(500)
    assert_receive {:grizzly, :report, get_command}, 500
    assert get_command.name == :firmware_update_md_get
    :timer.sleep(500)
    assert_receive {:grizzly, :report, status_command}, 500
    assert status_command.name == :firmware_update_md_status_report
  end
end
