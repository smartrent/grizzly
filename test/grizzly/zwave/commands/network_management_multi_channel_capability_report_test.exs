defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelCapabilityReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NetworkManagementMultiChannelCapabilityReport

  test "ensure command byte" do
    {:ok, command} = Commands.create(:network_management_multi_channel_capability_report)

    assert command.command_byte == 0x08
  end

  test "ensure name" do
    {:ok, command} = Commands.create(:network_management_multi_channel_capability_report)
    assert command.name == :network_management_multi_channel_capability_report
  end

  describe "encoding" do
    test "version 4 with 8 bit node id" do
      command = mk_cmd(0x04)

      assert NetworkManagementMultiChannelCapabilityReport.encode_params(command) ==
               <<0x01, 0x04, 0x09, 0x01, 0x10, 0x01, 0x20, 0x32, 0xF1, 0x00, 0x71, 0x25, 0xEF,
                 0x62, 0x63, 0x04::16>>
    end

    test "version 4 with 16 bit node id" do
      command = mk_cmd(0x4001)

      assert NetworkManagementMultiChannelCapabilityReport.encode_params(command) ==
               <<0x01, 0xFF, 0x09, 0x01, 0x10, 0x01, 0x20, 0x32, 0xF1, 0x00, 0x71, 0x25, 0xEF,
                 0x62, 0x63, 0x40, 0x01>>
    end

    test "version 4 - no data for end point" do
      {:ok, command} =
        Commands.create(
          :network_management_multi_channel_capability_report,
          seq_number: 0x01,
          node_id: 0x02,
          end_point: 0x00,
          generic_device_class: 0x00,
          specific_device_class: 0x00,
          command_classes: []
        )

      assert NetworkManagementMultiChannelCapabilityReport.encode_params(command) ==
               <<0x01, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02::16>>
    end
  end

  describe "parsing" do
    test "version 2-3" do
      {:ok, params} =
        NetworkManagementMultiChannelCapabilityReport.decode_params(
          <<0x01, 0x04, 0x09, 0x01, 0x10, 0x01, 0x20, 0x32, 0xF1, 0x00, 0x71, 0x25, 0xEF, 0x62,
            0x63>>
        )

      for {param, value} <- mk_expected_params(0x04) do
        assert params[param] == value
      end
    end

    test "no information" do
      expected_params = [
        seq_number: 0x01,
        node_id: 0x02,
        end_point: 0x00,
        generic_device_class: :unknown,
        specific_device_class: :unknown,
        command_classes: []
      ]

      {:ok, params} =
        NetworkManagementMultiChannelCapabilityReport.decode_params(
          <<0x01, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00>>
        )

      for {param, value} <- expected_params do
        assert params[param] == value
      end
    end

    test "version 4 with 8 bit node id" do
      {:ok, params} =
        NetworkManagementMultiChannelCapabilityReport.decode_params(
          <<0x01, 0x04, 0x09, 0x01, 0x10, 0x01, 0x20, 0x32, 0xF1, 0x00, 0x71, 0x25, 0xEF, 0x62,
            0x63, 0x04::16>>
        )

      for {param, value} <- mk_expected_params(0x04) do
        assert params[param] == value
      end
    end

    test "version 4 with 16 bit node id" do
      {:ok, params} =
        NetworkManagementMultiChannelCapabilityReport.decode_params(
          <<0x01, 0xFF, 0x09, 0x01, 0x10, 0x01, 0x20, 0x32, 0xF1, 0x00, 0x71, 0x25, 0xEF, 0x62,
            0x63, 0x1010::16>>
        )

      for {param, value} <- mk_expected_params(0x1010) do
        assert params[param] == value
      end
    end
  end

  defp mk_expected_params(node_id) do
    command_classes = [
      non_secure_supported: [:basic, :meter],
      non_secure_controlled: [],
      secure_supported: [:alarm, :switch_binary],
      secure_controlled: [:door_lock, :user_code]
    ]

    [
      seq_number: 0x01,
      node_id: node_id,
      end_point: 0x01,
      generic_device_class: :switch_binary,
      specific_device_class: :power_switch_binary,
      command_classes: command_classes
    ]
  end

  defp mk_cmd(node_id) do
    command_classes = [
      non_secure_supported: [:basic, :meter],
      non_secure_controlled: [],
      secure_supported: [:alarm, :switch_binary],
      secure_controlled: [:door_lock, :user_code]
    ]

    {:ok, cmd} =
      Commands.create(
        :network_management_multi_channel_capability_report,
        seq_number: 0x01,
        node_id: node_id,
        end_point: 0x01,
        generic_device_class: :switch_binary,
        specific_device_class: :power_switch_binary,
        command_classes: command_classes
      )

    cmd
  end
end
