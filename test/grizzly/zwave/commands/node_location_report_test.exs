defmodule Grizzly.ZWave.Commands.NodeLocationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeLocationReport

  test "creates the command and validates params" do
    params = [encoding: :ascii, location: "hall"]
    {:ok, _command} = NodeLocationReport.new(params)
  end

  test "encodes params correctly" do
    params = [encoding: :ascii, location: "hall"]
    {:ok, command} = NodeLocationReport.new(params)
    expected_binary = <<0x00::size(5), 0x00::size(3), 104, 97, 108, 108>>
    assert expected_binary == NodeLocationReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::size(5), 0x00::size(3), 104, 97, 108, 108>>
    {:ok, params} = NodeLocationReport.decode_params(binary_params)
    assert Keyword.get(params, :encoding) == :ascii
    assert Keyword.get(params, :location) == "hall"
  end
end
