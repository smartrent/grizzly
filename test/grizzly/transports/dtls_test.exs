defmodule Grizzly.Transports.DTLSTest do
  use ExUnit.Case, async: true

  alias Grizzly.Transport
  alias Grizzly.Transports.DTLS
  alias Grizzly.ZWave.Command

  describe "parse response" do
    test "when Z/IP Packet" do
      transport = %Transport{impl: DTLS, assigns: %{node_id: 5}}

      response =
        {:ssl, :fake_socket, <<0x23, 0x2, 0x80, 0x50, 0x1, 0x0, 0x0, 0x25, 0x2>>}

      {:ok, %Command{} = zip_packet} = DTLS.parse_response(response, transport: transport)

      command = Command.param!(zip_packet, :command)

      assert command.name == :switch_binary_get
    end

    test "when binary response" do
      transport = %Transport{impl: DTLS, assigns: %{node_id: 5}}

      response = {:ssl, :fake_socket, <<0x23, 0x2, 0x80, 0x50, 0x1, 0x0, 0x0, 0x25, 0x2>>}
      expected_out = <<0x23, 0x2, 0x80, 0x50, 0x1, 0x0, 0x0, 0x25, 0x2>>
      assert {:ok, expected_out} == DTLS.parse_response(response, raw: true, transport: transport)
    end

    test "when socket closes" do
      transport = %Transport{impl: DTLS, assigns: %{node_id: 5}}

      response = {:ssl_closed, :fake_socket}

      assert {:ok, :connection_closed} == DTLS.parse_response(response, transport: transport)
    end
  end
end
