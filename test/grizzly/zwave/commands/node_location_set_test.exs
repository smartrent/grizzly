defmodule Grizzly.ZWave.Commands.NodeLocationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeLocationSet

  test "creates the command and validates params" do
    params = [encoding: :ascii, location: "hall"]
    {:ok, _command} = NodeLocationSet.new(params)
  end

  test "encodes params correctly" do
    params = [encoding: :ascii, location: "hall"]
    {:ok, command} = NodeLocationSet.new(params)
    expected_binary = <<0x00::size(5), 0x00::size(3), 104, 97, 108, 108>>
    assert expected_binary == NodeLocationSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::size(5), 0x00::size(3), 104, 97, 108, 108>>
    {:ok, params} = NodeLocationSet.decode_params(binary_params)
    assert Keyword.get(params, :encoding) == :ascii
    assert Keyword.get(params, :location) == "hall"
  end
end
