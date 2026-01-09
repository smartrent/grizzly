defmodule Grizzly.ZWave.Commands.MultiChannelAggregatedMembersGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelAggregatedMembersGet

  test "creates the command and validates params" do
    params = [aggregated_end_point: 1]
    {:ok, _command} = Commands.create(:multi_channel_aggregated_members_get, params)
  end

  test "encodes params correctly" do
    params = [aggregated_end_point: 1]
    {:ok, command} = Commands.create(:multi_channel_aggregated_members_get, params)
    expected_binary = <<0x00::1, 0x01::7>>
    assert expected_binary == MultiChannelAggregatedMembersGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x00::1, 0x01::7>>
    {:ok, params} = MultiChannelAggregatedMembersGet.decode_params(params_binary)
    assert Keyword.get(params, :aggregated_end_point) == 1
  end
end
