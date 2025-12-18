defmodule Grizzly.FirmwareUpdates.FirmwareUpdateRunner.FirmwareUpdateTest do
  use ExUnit.Case, async: true

  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner.FirmwareUpdate
  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner.Image
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.FirmwareMDReport
  alias Grizzly.ZWave.Commands.FirmwareUpdateActivationReport
  alias Grizzly.ZWave.Commands.FirmwareUpdateMDGet
  alias Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReport
  alias Grizzly.ZWave.Commands.FirmwareUpdateMDStatusReport

  setup do
    image = Image.new("test/serialapi_controller_bridge_OTW_SD3503_US.gbl")

    firmware_update = %FirmwareUpdate{
      state: :started,
      image: image,
      manufacturer_id: 1,
      firmware_id: 2
    }

    [firmware_update: firmware_update]
  end

  describe "handling incoming command" do
    test "firmware update request report command - go", context do
      firmware_update = context[:firmware_update]
      {:ok, command} = FirmwareUpdateMDRequestReport.new(status: :ok)
      new_firmware_update = FirmwareUpdate.handle_command(firmware_update, command)
      assert new_firmware_update.state == :updating
    end

    test "firmware update request report command - stop", context do
      firmware_update = context[:firmware_update]
      {:ok, command} = FirmwareUpdateMDRequestReport.new(status: :insufficient_battery_level)
      new_firmware_update = FirmwareUpdate.handle_command(firmware_update, command)
      assert new_firmware_update.state == :complete
    end

    test "firmware update get command", context do
      firmware_update = %{context[:firmware_update] | state: :updating}
      {:ok, command} = FirmwareUpdateMDGet.new(number_of_reports: 2, report_number: 1)
      new_firmware_update = FirmwareUpdate.handle_command(firmware_update, command)
      assert new_firmware_update.state == :uploading
      assert new_firmware_update.fragments_wanted == 2
      assert new_firmware_update.fragment_index == 1
    end

    test "firmware update md status report", context do
      firmware_update = %{context[:firmware_update] | state: :updating}

      {:ok, command} =
        FirmwareUpdateMDStatusReport.new(status: :successful_restarting, wait_time: 10)

      new_firmware_update = FirmwareUpdate.handle_command(firmware_update, command)
      assert new_firmware_update.state == :complete
    end

    test "firmware md report", context do
      firmware_update = %{context[:firmware_update] | state: :uploading}

      {:ok, command} =
        FirmwareMDReport.new(
          manufacturer_id: 1,
          firmware_id: 2,
          checksum: 3,
          firmware_upgradable?: true,
          max_fragment_size: 1024,
          other_firmware_ids: []
        )

      new_firmware_update = FirmwareUpdate.handle_command(firmware_update, command)
      assert new_firmware_update.state == :uploading
      assert new_firmware_update.max_fragment_size == 1024

      assert Enum.count(new_firmware_update.image.fragments) >
               Enum.count(firmware_update.image.fragments)
    end

    test "firmware activation report", context do
      firmware_update = %{context[:firmware_update] | state: :activating}

      {:ok, command} =
        FirmwareUpdateActivationReport.new(
          manufacturer_id: 1,
          firmware_id: 2,
          hardware_version: 0,
          checksum: 3,
          firmware_update_status: :success,
          firmware_target: 0
        )

      new_firmware_update = FirmwareUpdate.handle_command(firmware_update, command)
      assert new_firmware_update.state == :complete
    end
  end

  describe "generating the next command" do
    test "start state to desired state of updating", context do
      firmware_update = context[:firmware_update]
      {command, new_firmware_update} = FirmwareUpdate.next_command(firmware_update, :updating)
      assert command.name == :firmware_update_md_request_get
      assert Command.param!(command, :manufacturer_id) == firmware_update.manufacturer_id
      assert Command.param!(command, :firmware_id) == firmware_update.firmware_id
      assert Command.param!(command, :firmware_target) == firmware_update.firmware_target
      assert Command.param!(command, :hardware_version) == firmware_update.hardware_version
      assert Command.param!(command, :fragment_size) == firmware_update.max_fragment_size

      assert Command.param!(command, :activation_may_be_delayed?) ==
               firmware_update.activation_may_be_delayed?

      assert Command.param!(command, :checksum) != nil
      assert new_firmware_update.state == :updating
      refute Enum.empty?(new_firmware_update.image.fragments)
    end

    test "updating state to uploading state", context do
      context_firmware_update = %{
        context[:firmware_update]
        | state: :uploading,
          fragment_index: 1
      }

      firmware_update = %{
        context_firmware_update
        | image: Image.fragment_image(context_firmware_update.image, 1024, 1)
      }

      {command, new_firmware_update} = FirmwareUpdate.next_command(firmware_update, :uploading)
      assert command.name == :firmware_update_md_report
      assert new_firmware_update.fragment_index == 2
      assert Command.param!(command, :report_number) == 1
      assert Command.param!(command, :last?) == false
      assert new_firmware_update.state == :uploading
    end

    test "dynamic transmission delays", %{firmware_update: firmware_update} do
      update = %{
        firmware_update
        | transmission_delay: 500
      }

      assert 500 == FirmwareUpdate.transmission_delay(update)

      update = FirmwareUpdate.put_last_transmission_speed(firmware_update, {40, :kbit_sec})
      assert 35 == FirmwareUpdate.transmission_delay(update)

      update = FirmwareUpdate.put_last_transmission_speed(update, {100, :kbit_sec})
      assert 15 == FirmwareUpdate.transmission_delay(update)

      update = FirmwareUpdate.put_last_transmission_speed(firmware_update, {9.6, :kbit_sec})
      assert 35 == FirmwareUpdate.transmission_delay(update)

      update = %{firmware_update | last_batch_size: 1}
      assert 0 == FirmwareUpdate.transmission_delay(update)
    end
  end
end
