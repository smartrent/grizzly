defmodule Grizzly.FirmwareUpdates.OTWUpdateRunner do
  @moduledoc """
  Task for running an OTW update for a Z-Wave controller module.
  """

  use Task

  require Logger

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWaveFirmware
  alias Grizzly.ZWaveFirmware.UpgradeSpec

  @alarm_id Grizzly.FirmwareUpdates.OTWUpdateInProgress

  @doc """
  Start the OTW update runner. Don't use this from IEx -- use `start_supervised/1` instead.

  ## Options

  * `:delay` - The delay before the update starts (default: 1 minute).
  """
  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :delay, :timer.minutes(1))
    Task.start_link(__MODULE__, :run, [opts])
  end

  @doc """
  Start the OTW update runner under `Grizzly.TaskSupervisor`.

  Same options as `start_link/1`.
  """
  def start_supervised(opts \\ []) do
    opts = Keyword.put_new(opts, :delay, 0)
    Task.Supervisor.start_child(Grizzly.TaskSupervisor, __MODULE__, :run, [opts])
  end

  @doc false
  def run(opts) do
    Process.sleep(opts[:delay])

    opts = Grizzly.options()
    version = version_from_zipgateway()

    _ =
      with %UpgradeSpec{} <- ZWaveFirmware.find_upgrade_spec(opts.zwave_firmware.specs, version) do
        # Once we decide to run, register the process name. This is a little trick
        # that lets us block commands sent via `Grizzly.send_command` while the update
        # is running while still allowing us to send a command to get the Z-Wave module
        # version from Z/IP Gateway.
        :alarm_handler.set_alarm({@alarm_id, []})
        Process.register(self(), __MODULE__)
        ZWaveFirmware.maybe_run_zwave_firmware_update(opts)
      else
        nil ->
          :ok
      end

    :ok
  after
    :alarm_handler.clear_alarm(@alarm_id)
  end

  defp version_from_zipgateway() do
    with {:ok, %{command: %Command{} = cmd}} <-
           Grizzly.send_command(1, :version_zwave_software_get) do
      Command.param!(cmd, :host_interface_version)
    else
      {:error, :timeout} ->
        Logger.warning("[Grizzly] Failed to get Z-Wave software version from Z/IP Gateway")
        nil
    end
  end
end
