defmodule Grizzly.ZWave.Commands.ZipNdInverseNodeSolicitationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZipNdInverseNodeSolicitation

  test "creates the command and validates params" do
    assert {:ok, _cmd} = ZipNdInverseNodeSolicitation.new(node_id: 5, local: true)
  end

  test "encodes params correctly" do
    expected_binary = <<0::4, 1::1, 0::3, 16::8>>
    {:ok, cmd} = ZipNdInverseNodeSolicitation.new(node_id: 16, local: true)
    assert expected_binary == ZipNdInverseNodeSolicitation.encode_params(cmd)

    expected_binary = <<0::8, 254::8>>
    {:ok, cmd} = ZipNdInverseNodeSolicitation.new(node_id: 254, local: false)
    assert expected_binary == ZipNdInverseNodeSolicitation.encode_params(cmd)

    expected_binary = <<0::8, 0xFF::8, 500::16>>
    {:ok, cmd} = ZipNdInverseNodeSolicitation.new(node_id: 500, local: false)
    assert expected_binary == ZipNdInverseNodeSolicitation.encode_params(cmd)
  end

  test "decodes params correctly" do
    assert {:ok, params} = ZipNdInverseNodeSolicitation.decode_params(<<0::4, 1::1, 0::3, 16::8>>)
    assert params[:node_id] == 16
    assert params[:local]

    assert {:ok, params} = ZipNdInverseNodeSolicitation.decode_params(<<0::8, 254::8>>)
    assert params[:node_id] == 254
    refute params[:local]

    assert {:ok, params} = ZipNdInverseNodeSolicitation.decode_params(<<0::8, 0xFF::8, 500::16>>)
    assert params[:node_id] == 500
    refute params[:local]
  end
end
