defmodule Grizzly.ZWave.NodeIdListTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.NodeIdList

  test "all 8 bit node id are able to parse" do
    binary = make_binary(29, 0xFF)
    list = Enum.to_list(1..232)

    assert list == NodeIdList.parse(binary)
  end

  test "able to parse 16 bit node ids" do
    eight_bit = make_binary(29, 0x00)
    # another 29 more devices, since each node id is not 16 bits we us 58 as the
    # length (29 * 2)
    extended_ids_list_length = <<0x00, 29>>
    extended_ids_binary = make_binary(29, 0xFF)

    node_id_list_binary =
      <<eight_bit::binary, extended_ids_list_length::binary, extended_ids_binary::binary>>

    ## with extend node ids the first one is 256 and we add another 232 node ids
    ## (including 256) so that is 488 is the highest node id for this test
    expected_list = Enum.to_list(256..487)

    assert expected_list == NodeIdList.parse(node_id_list_binary)
  end

  test "support both 16 bit nodes and a 8 bit node ids" do
    eight_bit = make_binary(29, 0xFF)

    extended_ids_list_length = <<0x00, 29>>
    extended_ids_binary = make_binary(29, 0xFF)

    node_id_list_binary =
      <<eight_bit::binary, extended_ids_list_length::binary, extended_ids_binary::binary>>

    expected_list = Enum.to_list(1..232) ++ Enum.to_list(256..487)

    assert expected_list == NodeIdList.parse(node_id_list_binary)
  end

  def make_binary(number_of_bytes, byte) do
    Enum.reduce(1..number_of_bytes, <<>>, fn _, bin -> <<bin::binary, byte>> end)
  end
end
