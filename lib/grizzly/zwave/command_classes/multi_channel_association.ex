defmodule Grizzly.ZWave.CommandClasses.MultiChannelAssociation do
  @moduledoc """
  "MultiChannelAssociation" Command Class

  The Multi Channel Association Command Class is used to manage associations to Multi Channel End
  Point destinations as well as to NodeID destinations.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave

  @marker 0x00

  @type node_endpoint :: [node: ZWave.node_id(), bit_address: 0 | 1, endpoint: 1..127]

  @impl true
  def byte(), do: 0x8E

  @impl true
  def name(), do: :multi_channel_association

  @spec encode_node_endpoints([node_endpoint]) :: binary
  def encode_node_endpoints(node_endpoints) do
    for node_endpoint <- node_endpoints, into: <<>> do
      node_id = Keyword.fetch!(node_endpoint, :node)
      bit_address = Keyword.fetch!(node_endpoint, :bit_address)
      endpoint = Keyword.fetch!(node_endpoint, :endpoint)
      <<node_id, bit_address::1, endpoint::7>>
    end
  end

  @spec decode_nodes_and_node_endpoints(binary) :: {[ZWave.node_id()], [node_endpoint]}
  def decode_nodes_and_node_endpoints(binary) do
    bin_list = :erlang.binary_to_list(binary)
    marker_index = Enum.find_index(bin_list, &(&1 == @marker))

    if marker_index == nil do
      {bin_list, []}
    else
      {node_ids, [_ | node_endpoint_bytes]} = Enum.split(bin_list, marker_index)

      node_endpoints =
        for [node_id, endpoint_byte] <- Enum.chunk_every(node_endpoint_bytes, 2) do
          <<bit_address::1, endpoint::7>> = <<endpoint_byte>>
          [node: node_id, bit_address: bit_address, endpoint: endpoint]
        end

      {node_ids, node_endpoints}
    end
  end
end
