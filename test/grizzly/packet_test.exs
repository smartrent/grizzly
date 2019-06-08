defmodule Grizzly.Packet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet

  test "decodes a packet that is not in a Z/IP frame" do
    raw_packet = <<0x72>>

    assert %Packet{raw?: true, body: %{command_class: :manufacturer_specific}} ==
             Packet.decode(raw_packet)
  end
end
