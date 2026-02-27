defmodule Grizzly.ZWave.Commands.AssociationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  # (<<gi, max_nodes, reports_to_follow, nodes_bin::binary>>)
  test "encodes params correctly" do
    params = [
      grouping_identifier: 2,
      max_nodes_supported: 5,
      nodes: [4, 5, 6],
      reports_to_follow: 0
    ]

    {:ok, command} = Commands.create(:association_report, params)
    expected_binary = <<0x85, 0x03, 0x02, 0x05, 0x00, 0x04, 0x05, 0x06>>
    assert expected_binary == Grizzly.encode_command(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x85, 0x03, 0x02, 0x05, 0x00, 0x04, 0x05, 0x06>>
    {:ok, cmd} = Grizzly.decode_command(binary_params)
    assert Keyword.get(cmd.params, :grouping_identifier) == 2
    assert Keyword.get(cmd.params, :max_nodes_supported) == 5
    assert Keyword.get(cmd.params, :reports_to_follow) == 0
    assert Enum.sort(Keyword.get(cmd.params, :nodes)) == [4, 5, 6]
  end
end
