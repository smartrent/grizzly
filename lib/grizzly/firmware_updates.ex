defmodule Grizzly.FirmwareUpdates do
  @moduledoc """
  Module for upgrading firmware on target devices.

  Required options:

  * `manufacturer_id` - The unique id indentifying the manufacturer of the target device
  * `firmware_id` - The id of the current firmware

  Other options:

  * `device_id` - Node id of the device to be updated. Defaults to 1 (controller)
  * `firmware_target` - The firwmare target id. Defaults to 0 (the ZWave chip)
  * `max_fragment_size` - The maximum number of bytes that will be transmitted at a time. Defaults to 2048.
  * `hardware_version` - The current hardware version of the device to be updated. Defaults to 0.
  * `activation_may_be_delayed?` - Whether it is permitted for the device may delay the actual firmware update. Defaults to false.
  * `handler` - The process that will receive callbacks. Defaults to the caller.any()

  The firmware update process is as follows:

    1. Grizzly sends a `firmware_md_get` command to the target device to get the manufacturer_id, hardware_id, max_fragment size,
    among other info needed to specify a firmware update request. The info is returned via a `firmware_md_report` command.

    2. Grizzly uses this info to send a `firmware_update_md_request` command to the target device, telling it to initiate the image
    uploading process. The checksum of the entire firmware image is added to the request. The target device says yeah or nay via a
    `firmware_update_md_request_report` command.

    3. If the target device agrees to have its firmware updated, it next sends a first `firmware_update_md_get` command to Grizzly asking
    for a number_of_reports (a bunch of firmware image fragment uploads) starting at fragment `report_number`.

    4. Grizzly responds by sending the requested series of `firmware_update_md_report` commands to the target device, each one containing
    a firmware image fragment, with a checksum for the command.

    5. Once a series of uploads is completed, the target device either asks for more fragments via another `firmware_update_md_get` command,
    or it sends a `firmware_update_md_status_report` command either to cancel the yet incomplete upload (bad command checksums!),
    or to announce that the update has completed either successfully (with some info about what happens next) or in failure
    (invalid overall image checksum!).

    6. As part of a successful `firmware_update_md_status_report` command, the target device tells Grizzly whether the new firmware
    needs to be activated. If it does, Grizzly would then be expected to send a `firmware_update_activation_set` command which success
    is reported by the target device via a `firmware_update_activation_report` command.

  """

  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunnerSupervisor
  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner

  @type opt ::
          {:manufacturer_id, non_neg_integer}
          | {:firmware_id, non_neg_integer}
          | {:device_id, Grizzly.node_id()}
          | {:hardware_version, byte}
          | {:handler, pid() | module() | {module, keyword()}}
          | {:firmware_target, byte}
          | {:fragment_size, non_neg_integer}
          | {:activation_may_be_delayed?, boolean}

  @type image_path :: String.t()

  require Logger

  @doc """
  Starts the firmware update process
  """
  @spec start_firmware_update(image_path(), [opt()]) ::
          :ok | {:error, :image_not_found} | {:error, :busy}
  def start_firmware_update(firmware_image_path, opts) do
    with {:ok, runner} <-
           FirmwareUpdateRunnerSupervisor.start_runner(opts) do
      FirmwareUpdateRunner.start_firmware_update(runner, firmware_image_path)
    else
      {:error, :imgae_not_found} ->
        Logger.warn("[Grizzly] Firmware image file not found")
        {:error, :image_not_found}

      other ->
        Logger.warn("[Grizzly] Failed to start firmware update: #{inspect(other)}")
        {:error, :busy}
    end
  end

  @spec firmware_update_running?() :: boolean()
  def firmware_update_running?() do
    child_count = DynamicSupervisor.count_children(FirmwareUpdateRunnerSupervisor)
    child_count.active == 1
  end

  @spec firmware_image_fragment_count :: {:ok, non_neg_integer} | {:error, :not_updating}
  def firmware_image_fragment_count() do
    if firmware_update_running?() do
      {:ok, FirmwareUpdateRunner.firmware_image_fragment_count()}
    else
      {:error, :not_updating}
    end
  end
end
