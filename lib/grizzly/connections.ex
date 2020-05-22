defmodule Grizzly.Connections do
  @moduledoc false

  # This module is helper functions for connections

  alias Grizzly.{ConnectionRegistry, ZIPGateway}
  alias Grizzly.Connections.Supervisor, as: ConnectionsSupervisor

  @doc """
  Close all the connections current open to the various
  nodes
  """
  @spec close_all() :: :ok
  def close_all() do
    ConnectionsSupervisor.close_all_connections()
  end

  def make_name(name), do: ConnectionRegistry.via_name(name)

  @spec get_transport_from_opts(keyword()) :: module()
  def get_transport_from_opts(opts) do
    case Keyword.get(opts, :transport) do
      nil ->
        Application.get_env(:grizzly, :transport, Grizzly.Transports.DTLS)

      transport ->
        transport
    end
  end

  def build_host_port_from_node_id(node_id) do
    host = ZIPGateway.host_for_node(node_id)
    port = ZIPGateway.port()

    {host, port}
  end

  def format_response(:ok), do: :ok
  def format_response({:ok, _} = res), do: res
  def format_response(res), do: {:ok, res}
end
