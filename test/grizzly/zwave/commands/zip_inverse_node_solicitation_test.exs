defmodule Grizzly.ZWave.Commands.ZipInverseNodeSolicitationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZipInverseNodeSolicitation

  test "creates the command and validates params" do
    params = [node_id: 2, local: true]
    {:ok, _command} = ZipInverseNodeSolicitation.new(params)
  end

  test "encodes params correctly" do
    params = [node_id: 2, local: true]
    {:ok, command} = ZipInverseNodeSolicitation.new(params)
    expected_binary = <<0x00::size(4), 0x01::size(1), 0x00::size(3), 0x02>>
    assert expected_binary == ZipInverseNodeSolicitation.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::size(4), 0x01::size(1), 0x00::size(3), 0x02>>
    {:ok, params} = ZipInverseNodeSolicitation.decode_params(binary_params)
    assert Keyword.get(params, :node_id) == 2
    assert Keyword.get(params, :local) == true
  end
end
