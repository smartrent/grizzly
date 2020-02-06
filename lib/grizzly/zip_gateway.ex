defmodule Grizzly.ZIPGateway do
  @moduledoc false

  alias Grizzly.ZIPGateway.{Supervisor, Config}

  @type run_opt :: {:serial_port, binary()}

  @default_port 41230

  # the host base is different for the LAN and PAN networks, we need to
  # probably handle this a little nicer
  @default_lan_host_base {0xFD00, 0xAAAA, 0, 0, 0, 0, 0}
  @default_pan_host_base {0xFD00, 0xBBBB, 0, 0, 0, 0, 0}

  @spec host_for_node(non_neg_integer()) :: :inet.ip_address()
  def host_for_node(1) do
    # unchecked assumption warning: that controller will always be node id
    # one. I think this is true for 99% of the cases?
    case Application.get_env(:grizzly, :zip_gateway) do
      nil ->
        Tuple.append(@default_lan_host_base, 1)

      zip_gateway_config ->
        replace_last(zip_gateway_config.host, 1) ||
          Tuple.append(@default_lan_host_base, 1)
    end
  end

  def host_for_node(node_id) do
    case Application.get_env(:grizzly, :zip_gateway) do
      nil ->
        Tuple.append(@default_pan_host_base, node_id)

      zip_gateway_config ->
        replace_last(zip_gateway_config.host, node_id) ||
          Tuple.append(@default_pan_host_base, node_id)
    end
  end

  @spec port() :: :inet.port_number()
  def port() do
    case Application.get_env(:grizzly, :zip_gateway) do
      nil ->
        @default_port

      zip_gateway_config ->
        Map.get(zip_gateway_config, :port) || @default_port
    end
  end

  @spec unsolicited_server_ip() :: :inet.ip_address()
  def unsolicited_server_ip() do
    case Application.get_env(:grizzly, :unsolicited_server) do
      nil ->
        Tuple.append(@default_lan_host_base, 0x0002)

      config ->
        config.ip || Tuple.append(@default_lan_host_base, 0x0002)
    end
  end

  @spec node_id_from_ip(:inet.ip_address()) :: Grizzly.node_id()
  def node_id_from_ip({_, _, _, node_id}), do: node_id
  def node_id_from_ip({_, _, _, _, _, _, _, node_id}), do: node_id

  @spec cfg_path() :: Path.t()
  def cfg_path(), do: Path.join(System.tmp_dir(), "zipgateway.cfg")

  @doc """
  Runs the `zipgateway` binary

  This validate the system is able to run the `zipgateway` binary and if
  so it will run it

  This function ensure that only one `zipgateway` binary is running ever
  adds supervision to the binary.

  Options:

    * `:serial_port` - The serial port the Z-Wave controller is connected to
  """
  @spec run_zipgateway([run_opt()]) :: :ok
  def run_zipgateway(opts \\ []) do
    on_start =
      Supervisor.run_zipgateway(
        serial_port: get_serial_port(opts),
        zipgateway_cfg: get_zipgateway_cfg(),
        zipgateway_cfg_path: cfg_path(),
        zipgateway_bin: find_zipgateway_bin()
      )

    case on_start do
      {:ok, _pid} -> :ok
      {:error, :already_started} -> :ok
    end
  end

  defp replace_last(nil, _node_id), do: nil
  defp replace_last({n1, n2, n3, _}, node_id), do: {n1, n2, n3, node_id}

  defp replace_last({n1, n2, n3, n4, n5, n6, n7, _}, node_id),
    do: {n1, n2, n3, n4, n5, n6, n7, node_id}

  defp get_serial_port(opts) do
    case Keyword.get(opts, :serial_port) do
      nil ->
        get_serial_port_from_application_env()

      serial_port ->
        serial_port
    end
  end

  defp get_serial_port_from_application_env() do
    case Application.get_env(:grizzly, :serial_port) do
      nil ->
        raise ArgumentError, """
        I was not able to find a serial port to the Z-Wave controller.

        Ensure this is configured in your config.exs file like so:

        config :grizzly,
          serial_port: "/dev/ttyUSB0"


        Your serial port might be named different depending on your system,
        so be sure double to check the name of your serial port when configuring.
        """

      serial_port ->
        serial_port
    end
  end

  defp get_zipgateway_cfg() do
    config = Application.get_env(:grizzly, :zipgateway_cfg, %{})

    Config.new(config)
  end

  defp find_zipgateway_bin() do
    path = Application.get_env(:grizzly, :zipgateway_path, "/usr/sbin/zipgateway")

    case File.stat(path) do
      {:error, _posix} ->
        raise ArgumentError, """
        Cannot find the zipgateway executable (looked for it in #{inspect(path)})

        If it is located somewhere else, please update the config:

        config :grizzly,
          zipgateway_path: "<<some path>>"
        """

      {:ok, _stat} ->
        path
    end
  end
end
