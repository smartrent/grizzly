defmodule Grizzly.ZWave.Commands.ZipNdNodeSolicitationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZipNdNodeSolicitation

  test "creates the command and validates params" do
    assert {:ok, _cmd} =
             ZipNdNodeSolicitation.new(ipv6_address: {0xFD00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1})
  end

  test "encodes params correctly" do
    {:ok, cmd} =
      ZipNdNodeSolicitation.new(ipv6_address: {0xFD00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1})

    expected_binary = <<0::8, 0::8, 0xFD00::16, 0::96, 0x1::16>>

    assert expected_binary == ZipNdNodeSolicitation.encode_params(cmd)
  end

  test "decodes params correctly" do
    assert {:ok, params} =
             ZipNdNodeSolicitation.decode_params(<<0::8, 0::8, 0xFD00::16, 0::96, 0x1::16>>)

    assert params[:ipv6_address] == {0xFD00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1}
  end
end
