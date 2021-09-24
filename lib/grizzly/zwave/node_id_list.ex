defmodule Grizzly.ZWave.NodeIdList do
  @moduledoc false

  # This module contains helpers for parsing and encoding a list of node ids
  # into a binary with bytes that are bitmasks of the node ids contained in the
  # list. This is common in network commands that contain a list of node ids in
  # the Z-Wave network.

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

  @typedoc """
  Options for when to encode the node list into a the binary mask

  * `:extended` - weather or not the node list contains extended ids
    (default `true`). For some command classes that predate Z-Wave long range
    the node list binary only contains 29 bytes. After command class versions
    that support 16 bit node ids the binary list will at minium contain 31
    bytes, 29 for the 8 bit node ids and 2 bytes for the byte size of the
    extended node id binary. If there are no extended node ids then this the
    byte size bytes will be `0x00000`.
  """
  @type to_binary_opt() :: {:extended, boolean()}

  @doc """
  Make a list of node ids into the binary node id list mask
  """
  @spec to_binary([Grizzly.ZWave.node_id()], [to_binary_opt()]) :: binary()
  def to_binary(node_id_list, opts \\ []) do
    contains_extended? = Keyword.get(opts, :extended, true)
    {node_ids, node_ids_extended} = :lists.partition(fn id -> id < 256 end, node_id_list)

    node_ids_binary = node_ids_to_binary(node_ids)

    if contains_extended? do
      extended_node_ids_binary = extended_node_ids_to_binary(node_ids_extended)
      extended_node_id_list_len = byte_size(extended_node_ids_binary)

      <<node_ids_binary::binary, <<extended_node_id_list_len::16>>,
        extended_node_ids_binary::binary>>
    else
      node_ids_binary
    end
  end

  defp node_ids_to_binary(node_ids, opts \\ []) do
    number_bytes = opts[:bytes] || 29
    offset = opts[:offset] || 0

    node_id_map = Enum.reduce(node_ids, %{}, fn id, hash -> Map.put(hash, id, id) end)

    for byte_index <- 0..(number_bytes - 1), into: <<>> do
      for bit_index <- 8..1, into: <<>> do
        node_id = byte_index * 8 + bit_index + offset
        if node_id_map[node_id], do: <<1::size(1)>>, else: <<0::size(1)>>
      end
    end
  end

  defp extended_node_ids_to_binary([]) do
    <<>>
  end

  defp extended_node_ids_to_binary(node_ids) do
    max = Enum.max(node_ids)
    # Subtract 31 because the extended node ids start at the
    # 31st byte of a node list binary mask. If we did not subtract
    # the number of bytes would start at 32.
    num_bytes = floor(max / 8) - 31

    node_ids_to_binary(node_ids, offset: 255, bytes: num_bytes)
  end
end
