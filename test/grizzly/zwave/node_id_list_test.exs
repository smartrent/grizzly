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

  test "encode all 8 bit node ids (max 232) with no extended node ids" do
    node_ids = Enum.to_list(1..232)
    node_id_list = make_binary(29, 0xFF)

    expected_binary = <<node_id_list::binary, 0x00, 0x00>>

    assert expected_binary == NodeIdList.to_binary(node_ids)
  end

  test "encode all 8 bit node ids (max 232) with extended node ids turned off" do
    node_ids = Enum.to_list(1..232)
    expected_binary = make_binary(29, 0xFF)

    assert expected_binary == NodeIdList.to_binary(node_ids, extended: false)
  end

  test "encode a bunch of extended node ids" do
    node_ids = Enum.to_list(256..487)
    extended = make_binary(29, 0xFF)
    eight_bit = make_binary(29, 0x00)

    expected_binary = <<eight_bit::binary, 0x00, 29, extended::binary>>

    assert expected_binary == NodeIdList.to_binary(node_ids)
  end

  test "encode some 8 bit and 16 bit node ids" do
    node_ids = [1, 25, 100, 56, 99, 230, 256, 264]

    expected_bin =
      <<0x1, 0x0, 0x0, 0x1, 0x0, 0x0, 0x80, 0x0, 0x0, 0x0, 0x0, 0x0, 0xC, 0x0, 0x0, 0x0, 0x0, 0x0,
        0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x20, 0x0, 0x2, 0x1, 0x1>>

    assert expected_bin == NodeIdList.to_binary(node_ids)
  end

  def make_binary(number_of_bytes, byte) do
    Enum.reduce(1..number_of_bytes, <<>>, fn _, bin -> <<bin::binary, byte>> end)
  end
end
