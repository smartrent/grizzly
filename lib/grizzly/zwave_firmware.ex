defmodule Grizzly.ZWaveFirmware do
  @moduledoc """
  Z-Wave module firmware upgrade support.

  ## Note on `zw_programmer`

  This module includes functionality to attempt to recover from a failed
  firmware upgrade that has left the Z-Wave module stuck at the bootloader. This
  functionality relies on `zw_programmer`'s `-a` flag, which (as of the 7.18.03
  release) does not work with 700- or 800-series modules.

  If you are using a 700- or 800-series module, you will need to implement this
  functionality yourself. This module invokes `zw_programmer` with a `-7` flag
  along with the `-a` flag when a 700/800-series module is specified.

  Because Z/IP Gateway is not licensed for distribution, we cannot provide a
  patch file. The modification is fairly straightforward, but if you need
  assistance, please open an issue on GitHub.
  """

  alias Grizzly.{FirmwareError, Options}

  require Logger

  @typedoc """
  The various status of a firmware update of the Z-Wave module

  * `:started` - the firmware update has been initiated and all validation of
    the firmware update is complete.
  * `{:done, :success}` - the firmware update of the Z-Wave module is successful.
  * `{:done, :skipped}` - no firmware update was applied.
  * `{:error, reason}` - A firmware update of the Z-Wave module was attempted
    but failed for some `reason`.
  """
  @type update_status ::
          :started | {:done, :success | :skipped} | {:error, FirmwareError.t()}

  @typedoc """
  Chip series (e.g. 500, 700, 800).
  """
  @type chip_series :: pos_integer()

  @typedoc """
  A function that performs a hard reset of the Z-Wave module. Used to detect
  if the module is stuck at the bootloader due to a previous failed upgrade.
  """
  @type module_reset_fun :: (-> :ok)

  defmodule UpgradeSpec do
    @moduledoc """
    A firmware upgrade specification used to determine if a firmware image can
    be applied given the running firmware version.
    """

    @typedoc """
    Firmware upgrade specification.

    * `version` - the version of the firmware image
    * `path` - the path to the firmware image
    * `applies_to` - the version requirement for the running firmware version
      that must be met for the upgrade to be applied
    """
    @type t :: %__MODULE__{
            version: Version.t(),
            path: Path.t(),
            applies_to: Version.requirement()
          }

    @enforce_keys [:version, :path, :applies_to]
    defstruct [:version, :path, :applies_to]

    @spec new(map() | keyword()) :: t()
    def new(opts) do
      struct(__MODULE__, opts)
    end

    @doc "Whether the spec applies given the current version."
    @spec applies?(t(), Version.t()) :: boolean()
    def applies?(%__MODULE__{} = spec, current_version) do
      # Only upgrades apply -- with the default bootloader, it's not possible to
      # downgrade or re-apply the same version.
      Version.compare(current_version, spec.version) == :lt &&
        Version.match?(current_version, spec.applies_to)
    end
  end

  @doc """
  Update the firmware on the Z-Wave module if an update is available
  """
  @spec maybe_run_zwave_firmware_update(Grizzly.Options.t()) :: :ok
  def maybe_run_zwave_firmware_update(%Options{} = opts) do
    stop_zipgateway()
    Process.sleep(1000)

    report(opts, :started)
    version = zwave_module_version(opts)

    case find_upgrade_spec(opts.zwave_firmware.specs, version) do
      nil ->
        Logger.info("[Grizzly] No matching firmware upgrade spec")
        report(opts, {:done, :skipped})

      %UpgradeSpec{version: target_version, path: path} ->
        Logger.info(
          "[Grizzly] Attempting to upgrade Z-Wave module to #{to_string(target_version)}"
        )

        apm_flag? = is_nil(version)
        upload_zwave_firmware_update(opts, path, apm_flag?)
        report(opts, {:done, :success})
    end

    :ok
  rescue
    e in FirmwareError ->
      error = %FirmwareError{e | stack_trace: Exception.format(:error, e, __STACKTRACE__)}
      report(opts, {:error, error})
      :ok

    # Firmware update not possible due to code error. Skip it.
    e in RuntimeError ->
      error = %FirmwareError{
        message: "Runtime error: #{e.message}",
        stack_trace: Exception.format(:error, e, __STACKTRACE__),
        fatal?: false
      }

      report(opts, {:error, error})
      :ok
  after
    restart_zipgateway()
  end

  def maybe_run_zwave_firmware_update(_), do: :ok

  @doc """
  Find an upgrade spec that applies to the current version. In case of multiple
  matches, returns the spec with the highest version. When the current version
  is nil, returns the spec with the highest version. If no specs match, returns
  nil.
  """
  @spec find_upgrade_spec([UpgradeSpec.t()], Version.t() | nil) ::
          UpgradeSpec.t() | nil
  def find_upgrade_spec(specs, nil = _current_version) do
    specs
    |> Enum.sort_by(& &1.version, {:desc, Version})
    |> List.first()
  end

  def find_upgrade_spec(specs, current_version) do
    specs
    |> Enum.sort_by(& &1.version, {:desc, Version})
    |> Enum.find(&UpgradeSpec.applies?(&1, current_version))
  end

  @doc false
  @spec zwave_module_version(Options.t()) :: Version.t() | nil
  def zwave_module_version(opts) do
    reset_zwave_module(opts)

    {answer, _} = zw_programmer(opts, ["-t"])
    Logger.debug("[Grizzly] Extracting current Z-Wave firmware version from #{inspect(answer)}")

    sapi_version_regex =
      ~r/Chip type: (?<chip_type>\d+).*SDK:\s*(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)/m

    cond do
      Regex.match?(sapi_version_regex, answer) ->
        %{"major" => major_s, "minor" => minor_s, "patch" => patch_s} =
          Regex.named_captures(sapi_version_regex, answer)

        Logger.info("[Grizzly] Current Z-Wave firmware version: #{major_s}.#{minor_s}.#{patch_s}")

        {major, ""} = Integer.parse(major_s)
        {minor, ""} = Integer.parse(minor_s)
        {patch, ""} = Integer.parse(patch_s)
        %Version{major: major, minor: minor, patch: patch}

      # Heuristic for detecting when the Z-Wave module is stuck at the bootloader since
      # the SAPI won't be available.
      String.contains?(answer, "SerialAPI: Retransmission 7") ->
        Logger.warning("[Grizzly] Z-Wave module appears to be stuck at the bootloader")
        nil

      # This happens when zw_programmer can't open the serial port
      String.contains?(answer, "Serial Init failed") ->
        raise FirmwareError, message: "zw_programmer said serial init failed", fatal?: true

      true ->
        raise FirmwareError, message: "unexpected zw_programmer output: #{answer}", fatal?: true
    end
  end

  @spec upload_zwave_firmware_update(Options.t(), Path.t(), boolean()) :: :ok
  defp upload_zwave_firmware_update(opts, firmware_path, apm_flag?) do
    Logger.info("[Grizzly] Uploading firmware image #{firmware_path} to #{opts.serial_port}}")

    args =
      cond do
        apm_flag? && opts.zwave_firmware.chip_series in [700, 800] ->
          ["-a", "-7"]

        apm_flag? ->
          ["-a"]

        true ->
          []
      end

    {result, code} = zw_programmer(opts, ["-p", firmware_path | args])

    if code == 0 do
      Logger.info("[Grizzly] Z-Wave firmware upgrade successful")
      :ok
    else
      reset_zwave_module(opts)
      raise FirmwareError, message: "zw_programmer exited with #{code}: #{result}", fatal?: true
    end
  end

  @spec zw_programmer(Options.t(), [binary()]) :: {binary(), non_neg_integer()}
  defp zw_programmer(opts, args) do
    args = ["-s", opts.serial_port | args]

    Logger.info("[Grizzly] Executing #{opts.zw_programmer_path} #{Enum.join(args, " ")}")

    MuonTrap.cmd(opts.zw_programmer_path, args)
  end

  @spec reset_zwave_module(Options.t()) :: :ok
  defp reset_zwave_module(%Options{zwave_firmware: opts}) do
    if is_function(opts[:module_reset_fun], 0), do: opts.module_reset_fun.()

    :ok
  end

  @spec report(Options.t(), update_status()) :: :ok
  defp report(opts, status) do
    _ = Process.spawn(fn -> opts.status_reporter.zwave_firmware_update_status(status) end, [])
    Grizzly.Events.broadcast(:otw_firmware_update, status)

    :ok
  end

  defp stop_zipgateway() do
    Grizzly.stop_zipgateway()
  catch
    :exit, {:noproc, _} ->
      # The Z/IP Gateway supervisor isn't running.
      :ok
  end

  defp restart_zipgateway() do
    Grizzly.restart_zipgateway()
  catch
    :exit, {:noproc, _} ->
      # The Z/IP Gateway supervisor isn't running.
      :ok
  end
end
