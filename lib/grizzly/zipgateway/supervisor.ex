defmodule Grizzly.ZIPGateway.Supervisor do
  @moduledoc false

  # Supervisor for the `zipgateway` system process
  use Supervisor

  alias Grizzly.Options
  alias Grizzly.ZIPGateway.Config

  @spec start_link(Options.t()) :: Supervisor.on_start()
  def start_link(options) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl Supervisor
  def init(options) do
    Supervisor.init(children(options), strategy: :one_for_one)
  end

  defp children(options) do
    if options.run_zipgateway do
      [make_zipgateway_child_spec(options)]
    else
      []
    end
  end

  defp make_zipgateway_child_spec(options) do
    :ok = system_checks(options)

    :ok =
      options |> Options.to_zipgateway_config() |> Config.write(options.zipgateway_config_path)

    _ = System.cmd("modprobe", ["tun"])

    priv = Application.app_dir(:grizzly, "priv")

    {MuonTrap.Daemon,
     [
       options.zipgateway_binary,
       ["-c", options.zipgateway_config_path, "-s", options.serial_port],
       [cd: priv, log_output: :debug]
     ]}
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
        Grizzly.Supervisor.start_link(zipgateay_path: <path>)
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
