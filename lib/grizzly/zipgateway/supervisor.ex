defmodule Grizzly.ZIPGateway.Supervisor do
  @moduledoc false

  # Supervisor for the `zipgateway` system process
  use DynamicSupervisor
  require Logger

  alias Grizzly.ZIPGateway.Config

  @type run_opt ::
          {:serial_port, binary()}
          | {:zipgateway_bin, Path.t()}
          | {:zipgateway_cfg, Config.t()}
          | {:zipgateway_cfg_path, Path.t()}

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def run_zipgateway(opts) do
    zipgateway_bin = Keyword.fetch!(opts, :zipgateway_bin)
    serial_port = Keyword.fetch!(opts, :serial_port)
    zipgateway_cfg_path = Keyword.fetch!(opts, :zipgateway_cfg_path)
    priv = Application.app_dir(:grizzly, "priv")

    _ =
      Logger.info("""
      Running zipgateway with:

      #{inspect(zipgateway_bin)} -c #{inspect(zipgateway_cfg_path)} -s #{inspect(serial_port)}

      From dir: #{inspect(priv)}
      """)

    child =
      {MuonTrap.Daemon,
       [
         zipgateway_bin,
         ["-c", zipgateway_cfg_path, "-s", serial_port],
         [cd: priv, log_output: :debug]
       ]}

    # TODO: make better! See what is currently in Grizzly
    _ = System.cmd("modprobe", ["tun"])

    :ok = check_serial_port(serial_port)

    # write the cfg after we know when can find the binary and everything in the system
    # looking good to run zipgateway
    :ok = Config.write(Keyword.get(opts, :zipgateway_cfg))

    DynamicSupervisor.start_child(__MODULE__, child)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 1)
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
end
