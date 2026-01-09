defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelCapabilityGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NetworkManagementMultiChannelCapabilityGet

  test "ensure command byte" do
    {:ok, command} = Commands.create(:network_management_multi_channel_capability_get)

    assert command.command_byte == 0x07
  end

  test "ensure name" do
    {:ok, command} = Commands.create(:network_management_multi_channel_capability_get)
    assert command.name == :network_management_multi_channel_capability_get
  end

  describe "encoding" do
    test "version 2-3" do
      {:ok, command} =
        Commands.create(
          :network_management_multi_channel_capability_get,
          seq_number: 0x01,
          node_id: 0x04,
          end_point: 0x01
        )

      for v <- 2..3 do
        assert NetworkManagementMultiChannelCapabilityGet.encode_params(command,
                 command_class_version: v
               ) == <<0x01, 0x04, 0x01>>
      end
    end

    test "version 4" do
      {:ok, command} =
        Commands.create(
          :network_management_multi_channel_capability_get,
          seq_number: 0x01,
          node_id: 0x0110,
          end_point: 0x03
        )

      assert NetworkManagementMultiChannelCapabilityGet.encode_params(command) ==
               <<0x01, 0xFF, 0x03, 0x01, 0x10>>
    end
  end

  describe "parsing" do
    test "version 2-3" do
      expected_params = [seq_number: 0x01, node_id: 0x04, end_point: 0x02]

      {:ok, params} =
        NetworkManagementMultiChannelCapabilityGet.decode_params(<<0x01, 0x04, 0x02>>)

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end

    test "version 4 with 8 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x10, end_point: 0x05]

      {:ok, params} =
        NetworkManagementMultiChannelCapabilityGet.decode_params(<<0x01, 0x10, 0x05, 0x00::16>>)

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end

    test "version 4 with 16 bit node id" do
      expected_params = [seq_number: 0x01, node_id: 0x1010, end_point: 0x05]

      {:ok, params} =
        NetworkManagementMultiChannelCapabilityGet.decode_params(<<0x01, 0xFF, 0x05, 0x10, 0x10>>)

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end
  end
end
