defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointReport

  test "ensure command byte" do
    {:ok, command} = Commands.create(:network_management_multi_channel_end_point_report)

    assert command.command_byte == 0x06
  end

  test "ensure name" do
    {:ok, command} = Commands.create(:network_management_multi_channel_end_point_report)
    assert command.name == :network_management_multi_channel_end_point_report
  end

  describe "encoding" do
    test "version 4 default no aggregated end points 8 bit node id" do
      {:ok, command} =
        Commands.create(
          :network_management_multi_channel_end_point_report,
          seq_number: 0x01,
          node_id: 0x01,
          individual_end_points: 10
        )

      assert NetworkManagementMultiChannelEndPointReport.encode_params(nil, command) ==
               <<0x01, 0x01, 0x00, 0x0A, 0x00, 0x01::16>>
    end

    test "version 4 default no aggregated end points 16 bit node id" do
      {:ok, command} =
        Commands.create(
          :network_management_multi_channel_end_point_report,
          seq_number: 0x01,
          node_id: 0x0110,
          individual_end_points: 10
        )

      assert NetworkManagementMultiChannelEndPointReport.encode_params(nil, command) ==
               <<0x01, 0xFF, 0x00, 0x0A, 0x00, 0x01, 0x10>>
    end

    test "version 4 with aggregated end points" do
      {:ok, command} =
        Commands.create(
          :network_management_multi_channel_end_point_report,
          seq_number: 0x01,
          node_id: 0x0110,
          individual_end_points: 10,
          aggregated_end_points: 15
        )

      assert NetworkManagementMultiChannelEndPointReport.encode_params(nil, command) ==
               <<0x01, 0xFF, 0x00, 0x0A, 0x0F, 0x01, 0x10>>
    end
  end

  describe "parsing" do
    test "version 2-3" do
      expected_params = [
        seq_number: 0x01,
        node_id: 0x04,
        individual_end_points: 100,
        aggregated_end_points: 10
      ]

      {:ok, params} =
        NetworkManagementMultiChannelEndPointReport.decode_params(
          nil,
          <<0x01, 0x04, 0x00, 0x64, 0x0A>>
        )

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end

    test "version 4 with 8 bit node id" do
      expected_params = [
        seq_number: 0x01,
        node_id: 0x10,
        individual_end_points: 100,
        aggregated_end_points: 10
      ]

      {:ok, params} =
        NetworkManagementMultiChannelEndPointReport.decode_params(
          nil,
          <<0x01, 0x10, 0x00, 0x64, 0x0A, 0x10::16>>
        )

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end

    test "version 4 with 16 bit node id" do
      expected_params = [
        seq_number: 0x01,
        node_id: 0x1010,
        individual_end_points: 100,
        aggregated_end_points: 10
      ]

      {:ok, params} =
        NetworkManagementMultiChannelEndPointReport.decode_params(
          nil,
          <<0x01, 0xFF, 0x00, 0x64, 0x0A, 0x10, 0x10>>
        )

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end
  end
end
