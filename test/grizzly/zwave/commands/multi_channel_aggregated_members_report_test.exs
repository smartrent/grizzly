defmodule Grizzly.ZWave.Commands.MultiChannelAggregatedMembersReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelAggregatedMembersReport

  test "creates the command and validates params" do
    params = [aggregated_end_point: 1, members: [2, 8, 9]]
    {:ok, _command} = Commands.create(:multi_channel_aggregated_members_report, params)
  end

  test "encodes params correctly" do
    params = [aggregated_end_point: 1, members: [2, 8, 9]]
    {:ok, command} = Commands.create(:multi_channel_aggregated_members_report, params)
    expected_binary = <<0x00::1, 0x01::7, 0x02, 0x82, 0x01>>
    assert expected_binary == MultiChannelAggregatedMembersReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x00::1, 0x01::7, 0x02, 0x82, 0x01>>
    {:ok, params} = MultiChannelAggregatedMembersReport.decode_params(params_binary)
    assert Keyword.get(params, :aggregated_end_point) == 1
    assert Keyword.get(params, :members) == [2, 8, 9]
  end
end
