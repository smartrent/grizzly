defmodule Grizzly.ZIPGatewayTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Options, ZIPGateway}

  test "get IP for node id 1 with IPv6" do
    assert {0xFD00, 0xBBBB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01} ==
             ZIPGateway.host_for_node(1, Options.new())
  end

  test "get IP for Gateway with IPv6" do
    assert {0xFD00, 0xAAAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01} ==
             ZIPGateway.host_for_node(:gateway, Options.new())
  end
end
