defmodule Grizzly.ZWave.NodeIdList do
  @moduledoc false

  @node_ids_list_len 29

  @doc """
  Parse a binary mask of node ids
  """
  @spec parse(binary()) :: [Grizzly.ZWave.node_id()]
  def parse(node_ids) when byte_size(node_ids) == @node_ids_list_len do
    unmask(node_ids, &node_id_modifier/2)
  end

  def parse(
        <<node_ids::binary-size(@node_ids_list_len), extended_node_ids_list_len::16,
          extended_node_ids_list::binary-size(extended_node_ids_list_len)>>
      ) do
    unmask(node_ids, &node_id_modifier/2) ++
      unmask(extended_node_ids_list, &node_id_extended_modifier/2)
  end

  defp unmask(node_ids_bin, modifier) do
    unmask(node_ids_bin, 0, [], modifier)
  end

  defp unmask(<<>>, _byte_offset, node_ids_list, _modifier) do
    Enum.sort(node_ids_list)
  end

  defp unmask(<<masked_byte::binary-size(1), rest::binary>>, byte_offset, node_id_list, modifier) do
    new_node_id_list = add_node_ids_in_byte(masked_byte, node_id_list, byte_offset, modifier)

    unmask(rest, byte_offset + 1, new_node_id_list, modifier)
  end

  defp add_node_ids_in_byte(byte, node_id_list, byte_offset, modifier) do
    <<eight::1, seven::1, six::1, five::1, four::1, three::1, two::1, one::1>> = byte

    node_ids = [
      {one, 1},
      {two, 2},
      {three, 3},
      {four, 4},
      {five, 5},
      {six, 6},
      {seven, 7},
      {eight, 8}
    ]

    Enum.reduce(node_ids, node_id_list, fn
      {0, _id}, ids -> ids
      {1, id}, ids -> [modifier.(id, byte_offset) | ids]
    end)
  end

  defp node_id_modifier(node_id, byte_offset), do: node_id + byte_offset * 8

  defp node_id_extended_modifier(node_id, byte_offset),
    do: node_id_modifier(node_id, byte_offset) + 255
end
