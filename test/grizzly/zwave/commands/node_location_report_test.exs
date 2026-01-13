defmodule Grizzly.ZWave.Commands.NodeLocationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NodeLocationReport

  test "creates the command and validates params" do
    params = [encoding: :ascii, location: "hall"]
    {:ok, _command} = Commands.create(:node_location_report, params)
  end

  test "encodes params correctly" do
    params = [encoding: :ascii, location: "hall"]
    {:ok, command} = Commands.create(:node_location_report, params)
    expected_binary = <<0x00::5, 0x00::3, 104, 97, 108, 108>>
    assert expected_binary == NodeLocationReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::5, 0x00::3, 104, 97, 108, 108>>
    {:ok, params} = NodeLocationReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :encoding) == :ascii
    assert Keyword.get(params, :location) == "hall"
  end
end
