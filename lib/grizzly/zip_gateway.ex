defmodule Grizzly.ZIPGateway do
  @moduledoc false

  # helper functions for working with the Z/IP Gateway

  alias Grizzly.Options
  alias Grizzly.ZWave

  # the host base is different for the LAN and PAN networks, we need to
  # probably handle this a little nicer
  @default_lan_host_base {0xFD00, 0xAAAA, 0, 0, 0, 0, 0}

  @doc """
  Get the IP address for the node id based of the LAN or PAN IP addresses
  """
  @spec host_for_node(ZWave.node_id() | :gateway, Options.t()) :: :inet.ip_address()
  def host_for_node(:gateway, options), do: options.lan_ip

  def host_for_node(node_id, options) do
    options.pan_ip
    |> Tuple.to_list()
    |> List.update_at(-1, fn _ -> node_id end)
    |> List.to_tuple()
  end

  @spec unsolicited_server_ip() :: :inet.ip_address()
  def unsolicited_server_ip() do
    default_lan_host =
      Tuple.insert_at(@default_lan_host_base, tuple_size(@default_lan_host_base), 0x0002)

    case Application.get_env(:grizzly, :unsolicited_server) do
      nil -> default_lan_host
      config -> config.ip || default_lan_host
    end
  end

  @spec node_id_from_ip(:inet.ip_address()) :: Grizzly.node_id()
  def node_id_from_ip({_, _, _, node_id}), do: node_id
  def node_id_from_ip({_, _, _, _, _, _, _, node_id}), do: node_id
end
