defmodule Grizzly.ZWave.Commands.MultiChannelAssociationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelAssociationReport

  describe "creates the command and validates params" do
    test "without node endpoints" do
      params = [
        grouping_identifier: 2,
        max_nodes_supported: 10,
        reports_to_follow: 0,
        nodes: [4, 5, 6],
        node_endpoints: []
      ]

      {:ok, _command} = Commands.create(:multi_channel_association_report, params)
    end

    test "with node endpoints" do
      params = [
        grouping_identifier: 2,
        max_nodes_supported: 10,
        reports_to_follow: 0,
        nodes: [4, 5, 6],
        node_endpoints: [
          [node: 7, bit_address: 0, endpoint: 2],
          [node: 8, bit_address: 1, endpoint: 3]
        ]
      ]

      {:ok, _command} = Commands.create(:multi_channel_association_report, params)
    end
  end

  describe "encodes params correctly" do
    test "without node endpoints" do
      params = [
        grouping_identifier: 2,
        max_nodes_supported: 10,
        reports_to_follow: 0,
        nodes: [4, 5, 6],
        node_endpoints: []
      ]

      {:ok, command} = Commands.create(:multi_channel_association_report, params)
      expected_binary = <<0x02, 0x0A, 0x00, 0x04, 0x05, 0x06>>
      assert expected_binary == MultiChannelAssociationReport.encode_params(command)
    end

    test "with node endpoints" do
      params = [
        grouping_identifier: 2,
        max_nodes_supported: 10,
        reports_to_follow: 0,
        nodes: [4, 5, 6],
        node_endpoints: [
          [node: 7, bit_address: 0, endpoint: 2],
          [node: 8, bit_address: 1, endpoint: 3]
        ]
      ]

      {:ok, command} = Commands.create(:multi_channel_association_report, params)

      expected_binary =
        <<0x02, 0x0A, 0x00, 0x04, 0x05, 0x06, 0x00, 0x07, 0x00::1, 0x02::7, 0x08, 0x01::1,
          0x03::7>>

      assert expected_binary == MultiChannelAssociationReport.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "without node endpoint" do
      binary_params = <<0x02, 0x0A, 0x00, 0x04, 0x05, 0x06>>
      {:ok, params} = MultiChannelAssociationReport.decode_params(binary_params)
      assert Keyword.get(params, :grouping_identifier) == 2
      assert Keyword.get(params, :max_nodes_supported) == 10
      assert Keyword.get(params, :reports_to_follow) == 0
      assert Enum.sort(Keyword.get(params, :nodes)) == [4, 5, 6]
      assert Enum.sort(Keyword.get(params, :node_endpoints)) == []
    end

    test "with node endpoint" do
      binary_params =
        <<0x02, 0x0A, 0x00, 0x04, 0x05, 0x06, 0x00, 0x07, 0x00::1, 0x02::7, 0x08, 0x01::1,
          0x03::7>>

      {:ok, params} = MultiChannelAssociationReport.decode_params(binary_params)
      assert Keyword.get(params, :grouping_identifier) == 2
      assert Keyword.get(params, :max_nodes_supported) == 10
      assert Keyword.get(params, :reports_to_follow) == 0
      assert Enum.sort(Keyword.get(params, :nodes)) == [4, 5, 6]

      assert Enum.sort(Keyword.get(params, :node_endpoints)) ==
               Enum.sort([
                 [node: 7, bit_address: 0, endpoint: 2],
                 [node: 8, bit_address: 1, endpoint: 3]
               ])
    end
  end
end
