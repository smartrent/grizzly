defmodule Grizzly.ZWave.Commands.MultiChannelAssociationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelAssociationGet

  test "creates the command and validates params" do
    params = [grouping_identifier: 2]
    {:ok, _command} = Commands.create(:multi_channel_association_get, params)
  end

  test "encodes params correctly" do
    params = [grouping_identifier: 2]
    {:ok, command} = Commands.create(:multi_channel_association_get, params)
    expected_binary = <<0x02>>
    assert expected_binary == MultiChannelAssociationGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02>>
    {:ok, params} = MultiChannelAssociationGet.decode_params(binary_params)
    assert Keyword.get(params, :grouping_identifier) == 2
  end
end
