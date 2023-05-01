defmodule Grizzly.ZIPGateway do
  @moduledoc false

  # helper functions for working with the Z/IP Gateway

  alias Grizzly.{Options, ZWave}

  @type network_key_type ::
          :s0
          | :s2_unauthenticated
          | :s2_authenticated
          | :s2_access_control
          | :s2_authenticated_long_range
          | :s2_access_control_long_range

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
end
