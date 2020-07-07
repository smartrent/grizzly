defmodule Grizzly.ZWave.Commands.AssociationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AssociationReport

  test "creates the command and validates params" do
    params = [
      grouping_identifier: 2,
      max_nodes_supported: 5,
      nodes: [4, 5, 6],
      reports_to_follow: 0
    ]

    {:ok, _command} = AssociationReport.new(params)
  end

  # (<<gi, max_nodes, reports_to_follow, nodes_bin::binary>>)
  test "encodes params correctly" do
    params = [
      grouping_identifier: 2,
      max_nodes_supported: 5,
      nodes: [4, 5, 6],
      reports_to_follow: 0
    ]

    {:ok, command} = AssociationReport.new(params)
    expected_binary = <<0x02, 0x05, 0x00, 0x04, 0x05, 0x06>>
    assert expected_binary == AssociationReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02, 0x05, 0x00, 0x04, 0x05, 0x06>>
    {:ok, params} = AssociationReport.decode_params(binary_params)
    assert Keyword.get(params, :grouping_identifier) == 2
    assert Keyword.get(params, :max_nodes_supported) == 5
    assert Keyword.get(params, :reports_to_follow) == 0
    assert Enum.sort(Keyword.get(params, :nodes)) == [4, 5, 6]
  end
end
