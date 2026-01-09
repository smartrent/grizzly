defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointGet

  test "ensure command byte" do
    {:ok, command} = Commands.create(:network_management_multi_channel_end_point_get)

    assert command.command_byte == 0x05
  end

  test "ensure name" do
    {:ok, command} = Commands.create(:network_management_multi_channel_end_point_get)
    assert command.name == :network_management_multi_channel_end_point_get
  end

  describe "encoding" do
    test "version 2-3" do
      {:ok, command} =
        Commands.create(:network_management_multi_channel_end_point_get,
          seq_number: 0x01,
          node_id: 0x04
        )

      for v <- 2..3 do
        assert NetworkManagementMultiChannelEndPointGet.encode_params(command,
                 command_class_version: v
               ) == <<0x01, 0x04>>
      end
    end

    test "version 4" do
      {:ok, command} =
        Commands.create(:network_management_multi_channel_end_point_get,
          seq_number: 0x01,
          node_id: 0x0110
        )

      assert NetworkManagementMultiChannelEndPointGet.encode_params(command) ==
               <<0x01, 0xFF, 0x01, 0x10>>
    end
  end

  describe "parsing" do
    test "version 2-3" do
      expected_params = [seq_number: 0x01, node_id: 0x04]
      {:ok, params} = NetworkManagementMultiChannelEndPointGet.decode_params(<<0x01, 0x04>>)

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end

    test "version 4 with 8 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x10]

      {:ok, params} =
        NetworkManagementMultiChannelEndPointGet.decode_params(<<0x01, 0x10, 0x00::16>>)

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end

    test "version 4 with 16 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x1010]

      {:ok, params} =
        NetworkManagementMultiChannelEndPointGet.decode_params(<<0x01, 0xFF, 0x10, 0x10>>)

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end
  end
end
