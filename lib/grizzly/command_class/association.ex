defmodule Grizzly.CommandClass.Association do
  alias Grizzly.Node

  @type associated_nodes :: [Node.node_id()]

  @spec decode_nodes(binary) :: associated_nodes
  def decode_nodes(binary) do
    :erlang.binary_to_list(binary)
  end
end
