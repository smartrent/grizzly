defmodule Grizzly.ZIPGateway.ZwaveFirmware do
  @moduledoc false

  alias Grizzly.ZIPGateway.FirmwareError

  require Logger

  @doc """
  Update the firmware on the Z-Wave module if an update is available
  """
  @spec maybe_run_zwave_firmware_update(Grizzly.Options.t()) :: :ok
  def maybe_run_zwave_firmware_update(options) do
    firmware_update_requested? = options.update_zwave_firmware

    if firmware_update_requested?, do: attempt_firmware_update(options)

    :ok
  end

  defp attempt_firmware_update(options) do
    zwave_module_info = zwave_module_info(options)

    case find_fw_image_file(options, zwave_module_info) do
      :no_fw_image_file ->
        report(options, :skipped)

      fw_image_file ->
        upload_zwave_firmware_update(fw_image_file, options)
        report(options, :success)
    end
  rescue
    e in FirmwareError ->
      reason = Exception.format(:error, e, __STACKTRACE__)
      Logger.error(
        "[Grizzly] SKIPPING firmware update due to #{inspect reason}"
      )
      report(options, {:error, reason})

    # Firmware update not possible due to code error. Skip it.
    e in RuntimeError ->
      Logger.error(
        "[Grizzly] Skipping firmware update due to #{Exception.format(:error, e, __STACKTRACE__)}"
      )

      report(options, {:error, :skipped})
  end

  # Looks for a valid upgrade fw image file
  defp find_fw_image_file(options, zwave_module_info) do
    firmware_info_list = options.zwave_firmware

    case find_upgrade_info(firmware_info_list, zwave_module_info) do
      %{path: path} ->
        path

      nil ->
        Logger.info(
          "[Grizzly] No firmware upgrade path found in #{inspect(firmware_info_list)} for current firmware #{inspect(zwave_module_info)}"
        )

        raise FirmwareError, message: :no_fw_image_file
    end
  end

  defp find_upgrade_info(
         firmware_info_list,
         %{chip_type: chip_type, version: current_version} = _current_firmware
       ) do
    Enum.find(firmware_info_list, fn %{
                                       chip_type: target_chip_type,
                                       version: target_version_s
                                     } ->
      target_version = Version.parse!(target_version_s)

      target_chip_type == chip_type and
        upgrade_valid?(current_version, target_version)
    end)
  end

  # {:ok, %{chip_type: 7, version: "7.15.2"}}
  defp zwave_module_info(options) do
    {answer, 0} = System.cmd(options.zw_programmer_path, ["-s", options.serial_port, "-t"])

    if String.contains?(answer, "Serial Init failed") do
      raise FirmwareError, message: :upgrade_failed
    else
      extract_zwave_module_info(answer)
    end
  end

  # "Using serial device /dev/ttyS4\nConnected to Serial device: OK\nSerial version: 9, Chip type: 7, Chip version: 0, SDK: 7.15.02, ..."
  # {:ok, %{chip_type: chip_type, version: current_version}}
  defp extract_zwave_module_info(answer) do
    Logger.info("[Grizzly] Extracting current version from #{inspect(answer)}")
    regex = ~r/Chip type: (?<chip_type>\d+).*SDK:\s*(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)/m

    %{"chip_type" => chip_type_s, "major" => major_s, "minor" => minor_s, "patch" => patch_s} =
      Regex.named_captures(regex, answer)

    {chip_type, ""} = Integer.parse(chip_type_s)
    {major, ""} = Integer.parse(major_s)
    {minor, ""} = Integer.parse(minor_s)
    {patch, ""} = Integer.parse(patch_s)
    %{chip_type: chip_type, version: %{major: major, minor: minor, patch: patch}}
  end

  defp upgrade_valid?(current_version, target_version) do
    cond do
      target_version.major > current_version.major ->
        true

      target_version.major == current_version.major and
          target_version.minor > current_version.minor ->
        true

      target_version.major == current_version.major and
        target_version.minor == current_version.minor and
          target_version.patch > current_version.patch ->
        true

      true ->
        false
    end
  end

  defp upload_zwave_firmware_update(firmware_path, options) do
    :ok = report(options, :started)

    Logger.info(
      "[Grizzly] Uploading ZWave controller firmware image #{firmware_path} via #{options.serial_port}}"
    )

    {_result, code} =
      System.cmd(options.zw_programmer_path, ["-s", options.serial_port, "-p", firmware_path])

    if code == 0 do
      Logger.info("[Grizzly] Hub firmware upgrade successful")
      :ok
    else
      raise FirmwareError, message: :upgrade_failed
    end
  end

  defp report(options, status) do
    # Report the firmware update status
    options.status_reporter.zwave_firmware_update_status(status)
  end
end
