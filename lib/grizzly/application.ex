defmodule Grizzly.Application do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    children =
      [
        Grizzly.Notifications,
        {Grizzly.SeqNumber, Enum.random(0..255)},
        {DynamicSupervisor, name: Grizzly.Conn.Supervisor, strategy: :one_for_one},
        {Grizzly.UnsolicitedServer, unsolicited_server_config()},
        {Grizzly.Controller, get_grizzly_config()},
        Grizzly.UnsolicitedServer.Socket.Supervisor,
        Grizzly.Inclusion,
        Grizzly.Network.State
      ]
      |> maybe_append_muontrap()

    opts = [strategy: :one_for_one, name: Grizzly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp unsolicited_server_config() do
    Grizzly.UnsolicitedServer.Config.new(
      ip_version: :inet6,
      ip_address: {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x0002}
    )
  end

  defp maybe_append_muontrap(children_list) do
    with :ok <- get_run_zipgateway_bin(),
         {:ok, serial_port} <- get_serial_port() do

      priv_dir = :code.priv_dir(:grizzly) |> to_string()
      check_for_tuntap(:os.type())
      zip_gateway_path = find_zip_gateway()
      [
        {MuonTrap.Daemon,
         [
           zip_gateway_path,
           ["-c", Path.join(priv_dir, "zipgateway.cfg"), "-s", serial_port],
           [cd: priv_dir, log_output: :debug]
         ]}
      ] ++ children_list
    else
      {:error, :no_serial_port} ->
        _ =
          Logger.error("""
          No serial port configured for Grizzly. Add :serial_port to the
          config options in your config.exs file like. For example:

          config :grizzly,
            serial_port: "/dev/ttyACM0"

          If you have questions about which serial port(s) your hardware
          supports either see the documentation about the nerves system at
          https://github.com/nerves-project or ask in the #nerves channel
          in the Elixir lang slack.
          """)

        children_list

      :no_run_zipgateway_bin ->
        children_list
    end
  end

  defp check_for_tuntap({:unix, :darwin}) do
    System.cmd("kextstat", [ "-b", "net.sf.tuntaposx.tap" ])
    |> elem(0)
    |> String.contains?("net.sf.tuntaposx.tap")
    |> case do: (
      true ->
        ; # all OK
      _ ->
        msg = """
        The kernel extension tuntab does not appear to be loaded. You
        can install it using `brew cask install tuntap`.
        """
        Logger.error(msg)
        raise(msg)
    )
  end

  defp find_zip_gateway do
    path = Application.get_env(:grizzly, :zipgateway_path, "/usr/sbin/zipgateway")
    case File.stat(path) do
      { :error, posix } ->
        msg = """
        Cannot find the zipgateway executable (looked for it at #{inspect path}.

        If it is located somewhere else, please update the config:

            config :grizzly,
              zipgateway_path: "«path»"
        """
        Logger.error(msg)
        raise(msg)
      { :ok, _stat } ->
        # could check the mode, but not really worth it
        path
    end
  end

  defp check_for_tuntap({:unix, _}) do
    _unused = System.cmd("modprobe", ["tun"])
  end

  defp get_serial_port() do
    case Application.get_env(:grizzly, :serial_port, {:error, :no_serial_port}) do
      {:error, _} = error -> error
      serial_port -> {:ok, serial_port}
    end
  end

  defp get_run_zipgateway_bin() do
    case Application.get_env(:grizzly, :run_zipgateway_bin, true) do
      true -> :ok
      false -> :no_run_zipgateway_bin
    end
  end

  defp get_grizzly_config() do
    case Application.get_env(:grizzly, Grizzly.Controller) do
      nil -> Grizzly.config()
      opts -> Grizzly.Conn.Config.new(opts)
    end
  end
end
