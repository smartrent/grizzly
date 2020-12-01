defmodule Grizzly.Transports.DTLSTest do
  use ExUnit.Case, async: true

  alias Grizzly.Transports.DTLS
  alias Grizzly.Transport.Response
  alias Grizzly.ZWave.Command

  describe "parse response" do
    test "when Z/IP Packet" do
      response =
        {:ssl, {:sslsocket, {:gen_udp, 123, :dtls_connection}, make_ref()},
         [0x23, 0x2, 0x80, 0x50, 0x1, 0x0, 0x0, 0x25, 0x2]}

      {:ok, %Response{command: zip_packet}} = DTLS.parse_response(response, [])

      command = Command.param!(zip_packet, :command)

      assert command.name == :switch_binary_get
    end

    test "when binary response" do
      response =
        {:ssl, {:sslsocket, {:gen_udp, 123, :dtls_connection}, make_ref()},
         [0x23, 0x2, 0x80, 0x50, 0x1, 0x0, 0x0, 0x25, 0x2]}

      expected_out = <<0x23, 0x2, 0x80, 0x50, 0x1, 0x0, 0x0, 0x25, 0x2>>
      assert {:ok, expected_out} == DTLS.parse_response(response, raw: true)
    end

    test "when socket closes" do
      response = {:ssl_closed, {:sslsocket, {:gen_udp, 123, :dtls_connection}, [123]}}

      assert {:ok, :connection_closed} == DTLS.parse_response(response, [])
    end
  end
end
