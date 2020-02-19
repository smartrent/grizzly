defmodule Grizzly.CommandClass.MultiChannelAssociation do
  alias Grizzly.Node
  require Logger

  @type associated_nodes :: [Node.node_id()]

  @type endpoints :: [endpoint]

  @type endpoint :: %{node_id: byte, endpoint: byte}

  @type multi_channel_association_report :: %{
          group: byte,
          max_nodes_supported: byte,
          nodes: associated_nodes,
          endpoints: endpoints
        }

  @multi_channel_association_marker 0x00

  def marker() do
    @multi_channel_association_marker
  end

  @spec encode_endpoints(endpoints) :: {:ok, binary}
  def encode_endpoints(endpoints) do
    encoded =
      Enum.reduce(
        endpoints,
        [],
        fn %{node_id: node_id, endpoint: endpoint}, acc ->
          [endpoint, node_id | acc]
        end
      )
      |> Enum.reverse()
      |> :erlang.list_to_binary()

    {:ok, encoded}
  end

  @spec decode_nodes_and_endpoints(binary) :: {associated_nodes, endpoints}
  def decode_nodes_and_endpoints(binary) do
    bytes = :erlang.binary_to_list(binary)
    marker_index = Enum.find_index(bytes, &(&1 == @multi_channel_association_marker))

    case Enum.split(bytes, marker_index) do
      {[], []} ->
        {[], []}

      {nodes, [_marker | endpoint_bytes]} ->
        endpoints = endpoints(endpoint_bytes)
        {nodes, endpoints}
    end
  end

  defp endpoints([]) do
    []
  end

  defp endpoints([node_id, endpoint | rest]) do
    [%{node_id: node_id, endpoint: endpoint} | endpoints(rest)]
  end
end
