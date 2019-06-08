defmodule Grizzly.Packet.Decode.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet.Decode

  test "gets the correct response type" do
    ack_response = <<0x00, 0x00, 0x40, 0x00>>

    assert [:ack_response] == Decode.get_packet_types(ack_response)
  end

  describe "Special raw packets to be handled" do
    test "Z/IP ND inverse node solicitation adversitement" do
      packet =
        <<0x58, 0x01, 0x00, 0x06, 0xFD, 0x00, 0xBB, 0xBB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0xDA, 0x23, 0xFE, 0x52>>

      assert Decode.raw(packet) == %{
               command_class: :zip_nd,
               command: :zip_node_advertisement,
               ip_address: {0xFD00, 0xBBBB, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006},
               home_id: <<0xDA, 0x23, 0xFE, 0x52>>,
               node_id: 0x06
             }
    end
  end
end
