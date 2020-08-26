defmodule Grizzly.ZIPGatewayTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Options, ZIPGateway}
  alias GrizzlyTest.Utils

  test "get IP for node id 1 with IPv6" do
    assert {0xFD00, 0xAAAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01} ==
             ZIPGateway.host_for_node(1, Options.new())
  end

  test "get IP for node id 1 with IPv4" do
    assert {0, 0, 0, 1} ==
             ZIPGateway.host_for_node(1, Utils.default_options())
  end

  test "get IP for a node other than node id 1 IPv6" do
    assert {0xFD00, 0xBBBB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05} ==
             ZIPGateway.host_for_node(5, Options.new())
  end

  test "get IP for a node other than node id 1 IPv4" do
    assert {0, 0, 0, 5} ==
             ZIPGateway.host_for_node(5, Utils.default_options())
  end
end
