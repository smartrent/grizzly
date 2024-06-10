defmodule Grizzly.ZWave.Commands.NodeNameReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeNameReport

  test "creates the command and validates params" do
    params = [encoding: :ascii, name: "motion"]
    {:ok, _command} = NodeNameReport.new(params)
  end

  test "encodes params correctly" do
    params = [encoding: :ascii, name: "motion"]
    {:ok, command} = NodeNameReport.new(params)
    expected_binary = <<0x00::5, 0x00::3, 109, 111, 116, 105, 111, 110>>
    assert expected_binary == NodeNameReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::5, 0x00::3, 109, 111, 116, 105, 111, 110>>
    {:ok, params} = NodeNameReport.decode_params(binary_params)
    assert Keyword.get(params, :encoding) == :ascii
    assert Keyword.get(params, :name) == "motion"
  end
end
