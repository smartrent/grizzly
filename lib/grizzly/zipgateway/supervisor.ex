defmodule Grizzly.ZIPGateway.Supervisor do
  @moduledoc false

  # Supervisor for the `zipgateway` system process
  use Supervisor

  alias Grizzly.{Indicator, Options}
  alias Grizzly.ZIPGateway.Config
  require Logger

  @zgw_eeprom_to_sqlite "/usr/bin/zgw_eeprom_to_sqlite"

  @spec start_link(Options.t()) :: Supervisor.on_start()
  def start_link(options) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl Supervisor
  def init(options) do
    Supervisor.init(child_specs(options), strategy: :one_for_one)
  end

  defp child_specs(options) do
    if options.run_zipgateway do
      zipgateway_child_specs(options)
    else
      []
    end
  end

  defp zipgateway_child_specs(options) do
    try_migrate_eeprom_to_sql(options)

    :ok = system_checks(options)

    :ok =
      options
      |> Options.to_zipgateway_config(use_database?())
      |> Config.write(options.zipgateway_config_path)

    _ = System.cmd("modprobe", ["tun"])

    priv = Application.app_dir(:grizzly, "priv")

    beam_notify_options = [
      name: "grizzly indicator",
      path: "/tmp/grizzly_beam_notify_socket",
      dispatcher: &Indicator.handle_event(&1, &2, options.indicator_handler)
    ]

    [
      {BEAMNotify, beam_notify_options},
      {MuonTrap.Daemon,
       [
         options.zipgateway_binary,
         ["-c", options.zipgateway_config_path, "-s", options.serial_port],
         [cd: priv, log_output: :debug]
       ]}
    ]
  end

  defp try_migrate_eeprom_to_sql(%{eeprom_file: eeprom_file, database_file: database_file}) do
    if use_database?() and
         eeprom_file != nil and
         database_file != nil and
         not File.exists?(database_file) and
         File.exists?(eeprom_file) do
      run_eeprom_to_sql_prog(eeprom_file, database_file)
    end

    :ok
  end

  defp use_database?() do
    File.exists?(@zgw_eeprom_to_sqlite)
  end

  defp run_eeprom_to_sql_prog(eeprom_file, database_file) do
    Logger.info("Running #{@zgw_eeprom_to_sqlite} -e #{eeprom_file} -d #{database_file}")

    case System.cmd(@zgw_eeprom_to_sqlite, ["-e", eeprom_file, "-d", database_file]) do
      {message, 0} ->
        Logger.info("Successfully migrated EEPROM to DB: #{inspect(message)}")
        :ok

      {message, _error_no} ->
        Logger.error("EEPROM to DB migration failed: #{inspect(message)}")
    end

    :ok
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
end
