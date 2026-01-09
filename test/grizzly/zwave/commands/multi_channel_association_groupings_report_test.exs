defmodule Grizzly.ZWave.Commands.MultiChannelMultiChannelAssociationGroupingsReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelAssociationGroupingsReport

  test "creates the command and validates params" do
    params = [supported_groupings: 5]
    {:ok, _command} = Commands.create(:multi_channel_association_groupings_report, params)
  end

  test "encodes params correctly" do
    params = [supported_groupings: 5]
    {:ok, command} = Commands.create(:multi_channel_association_groupings_report, params)
    expected_binary = <<0x05>>
    assert MultiChannelAssociationGroupingsReport.encode_params(command) == expected_binary
  end

  test "decodes params correctly" do
    binary_params = <<0x05>>
    {:ok, params} = MultiChannelAssociationGroupingsReport.decode_params(binary_params)
    assert Keyword.get(params, :supported_groupings) == 5
  end
end
