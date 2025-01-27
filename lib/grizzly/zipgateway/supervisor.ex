defmodule Grizzly.ZIPGateway.Supervisor do
  @moduledoc """
  Supervisor for the Z/IP Gateway process.
  """

  # Supervisor for the `zipgateway` system process
  use Supervisor

  alias Grizzly.{Indicator, Options}
  alias Grizzly.ZIPGateway.{Config, ExitMonitor, LogMonitor, SAPIMonitor}
  require Logger

  @doc """
  Restarts the Z/IP Gateway process. An error will be raised if `Grizzly.ZIPGateway.Supervisor`
  is not running.
  """
  @spec restart_zipgateway() :: :ok
  def restart_zipgateway() do
    _ = Supervisor.terminate_child(__MODULE__, Grizzly.ZIPGateway.ProcessSupervisor)
    {:ok, _} = Supervisor.restart_child(__MODULE__, Grizzly.ZIPGateway.ProcessSupervisor)
    :ok
  end

  @doc "Stops the Z/IP Gateway process if it is running."
  @spec stop_zipgateway() :: :ok
  def stop_zipgateway() do
    _ = Supervisor.terminate_child(__MODULE__, Grizzly.ZIPGateway.ProcessSupervisor)
    :ok
  end

  @spec start_link(Options.t()) :: Supervisor.on_start()
  def start_link(options) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl Supervisor
  def init(options) do
    Supervisor.init(child_specs(options), strategy: :rest_for_one)
  end

  defp child_specs(options) do
    if options.run_zipgateway do
      zipgateway_child_specs(options)
    else
      []
    end
  end

  defp zipgateway_child_specs(options) do
    :ok = system_checks(options)

    :ok =
      options
      |> Options.to_zipgateway_config()
      |> Config.ensure_files()
      |> Config.write(options.zipgateway_config_path)

    _ = System.cmd("modprobe", ["tun"])

    beam_notify_options = [
      name: "grizzly indicator",
      path: "/tmp/grizzly_beam_notify_socket",
      dispatcher: &Indicator.handle_event(&1, &2, options.indicator_handler)
    ]

    [
      {SAPIMonitor, [status_reporter: options.status_reporter]},
      LogMonitor,
      {BEAMNotify, beam_notify_options},
      zipgateway_process_supervisor_spec(options)
    ]
  end

  # Run MuonTrap.Daemon and ZIPGateway.ExitMonitor under a supervisor using the
  # `:rest_for_one` strategy. This isolates the Z/IP Gateway process from exits
  # in LogMonitor or BEAMNotify while allowing ExitMonitor to do cleanup when
  # Z/IP Gateway exits (chiefly, this means closing all DTLS connections).
  defp zipgateway_process_supervisor_spec(options) do
    priv = Application.app_dir(:grizzly, "priv")

    children = [
      {MuonTrap.Daemon,
       [
         options.zipgateway_binary,
         ["-c", options.zipgateway_config_path, "-s", options.serial_port],
         [
           name: Grizzly.ZIPGateway.Daemon,
           cd: priv,
           logger_fun: &zipgateway_log/1,
           exit_status_to_reason: &zipgateway_exit_status/1
         ]
       ]},
      ExitMonitor
    ]

    %{
      id: Grizzly.ZIPGateway.ProcessSupervisor,
      type: :supervisor,
      start:
        {Supervisor, :start_link,
         [children, [name: Grizzly.ZIPGateway.ProcessSupervisor, strategy: :rest_for_one]]}
    }
  end

  defp system_checks(options) do
    :ok = check_serial_port(options.serial_port)
    :ok = find_zipgateway_bin(options.zipgateway_binary)

    :ok
  end

  defp check_serial_port(serial_port) do
    if File.exists?(serial_port) do
      :ok
    else
      raise ArgumentError, """
      It looks like the serial port: #{inspect(serial_port)} is not available

      If you are using an USB dongle ensure that you have plugged it in and that
      you have configured the correct serial port.

      If you are using a Z-Wave controller embedded onto your system make sure you
      are using the correct serial port in the configuration.
      """
    end
  end

  defp find_zipgateway_bin(zipgateway_path) do
    case File.stat(zipgateway_path) do
      {:error, _posix} ->
        raise ArgumentError, """
        Cannot find the zipgateway executable (looked for it in #{inspect(zipgateway_path)})

        If it is located somewhere else, please pass the path to Grizzly.Supervisor

        ```
        Grizzly.Supervisor.start_link(zipgateway_path: <path>)
        ```

        ```
        {Grizzly.Supervisor, [zipgateway_path: <path>]}
        ```

        """

      {:ok, _stat} ->
        :ok
    end
  end

  @spec zipgateway_log(binary()) :: :ok
  defp zipgateway_log(message) do
    Logger.debug("zipgateway: " <> message)

    case GenServer.whereis(Grizzly.ZIPGateway.LogMonitor) do
      nil -> :ok
      pid -> send(pid, {:message, message})
    end

    :ok
  end

  defp zipgateway_exit_status(status) do
    :telemetry.execute(
      [:grizzly, :zipgateway, :crash],
      %{exit_status: status}
    )

    grizzly_opts = Grizzly.options()
    reset_zwave_module(grizzly_opts)

    :error_exit_status
  end

  @spec reset_zwave_module(Options.t()) :: :ok
  defp reset_zwave_module(%Options{zwave_firmware: opts}) do
    if is_function(opts[:module_reset_fun], 0), do: opts.module_reset_fun.()

    :ok
  end
end
