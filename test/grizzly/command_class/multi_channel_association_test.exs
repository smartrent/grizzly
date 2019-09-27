defmodule Grizzly.CommandClass.MultiChannelAssociation.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.MultiChannelAssociation

  describe "encoding" do
    test "encoding endpoints" do
      assert {:ok, <<0x02, 0x02, 0x03, 0x03, 0x03, 0x04>>} =
               MultiChannelAssociation.encode_endpoints([
                 %{node_id: 2, endpoint: 2},
                 %{node_id: 3, endpoint: 3},
                 %{node_id: 3, endpoint: 4}
               ])
    end
  end

  describe "decoding" do
    test "decoding nodes and endpoints" do
      assert {[2, 3],
              [
                %{node_id: 2, endpoint: 2},
                %{node_id: 3, endpoint: 3},
                %{node_id: 3, endpoint: 4}
              ]} ==
               MultiChannelAssociation.decode_nodes_and_endpoints(
                 <<0x02, 0x03, 0x00, 0x02, 0x02, 0x03, 0x03, 0x03, 0x04>>
               )
    end
  end
end
