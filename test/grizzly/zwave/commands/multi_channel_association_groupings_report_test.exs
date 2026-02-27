defmodule Grizzly.ZWave.Commands.MultiChannelMultiChannelAssociationGroupingsReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  test "encodes params correctly" do
    params = [supported_groupings: 5]
    {:ok, command} = Commands.create(:multi_channel_association_groupings_report, params)
    expected_binary = <<0x8E, 0x06, 0x05>>
    assert Grizzly.encode_command(command) == expected_binary
  end

  test "decodes params correctly" do
    binary_params = <<0x8E, 0x06, 0x05>>
    {:ok, cmd} = Grizzly.decode_command(binary_params)
    assert Keyword.get(cmd.params, :supported_groupings) == 5
  end
end
