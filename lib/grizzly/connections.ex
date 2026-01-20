defmodule Grizzly.Connections do
  @moduledoc false

  # This module is helper functions for connections

  alias Grizzly.Connections.Supervisor, as: ConnectionsSupervisor

  @type name() ::
          Grizzly.node_id()
          | :gateway
          | {:async, Grizzly.node_id()}
          | {:binary, Grizzly.node_id(), pid()}

  @doc """
  Close all the connections current open to the various
  nodes
  """
  @spec close_all() :: :ok
  def close_all() do
    ConnectionsSupervisor.close_all_connections()
  end

  @spec via_name(name()) ::
          {:via, Registry, {Grizzly.ConnectionRegistry, Grizzly.node_id()}} | pid()
  def via_name(pid) when is_pid(pid), do: pid

  def via_name(node_id) do
    {:via, Registry, {Grizzly.ConnectionRegistry, node_id}}
  end

  @spec get_transport_from_opts(keyword()) :: module()
  def get_transport_from_opts(opts) do
    case Keyword.get(opts, :transport) do
      nil ->
        Application.get_env(:grizzly, :transport, Grizzly.Transports.DTLS)

      transport ->
        transport
    end
  end

  def format_response(:ok), do: :ok
  def format_response({:ok, _} = res), do: res
  def format_response(res), do: {:ok, res}
end
