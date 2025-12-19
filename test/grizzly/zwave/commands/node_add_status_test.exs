defmodule Grizzly.ZWave.Commands.NodeAddStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeAddStatus
  alias Grizzly.ZWave.DSK

  describe "decoding report" do
    test "version 1" do
      report =
        <<0x01, 0x06, 0x00, 0x09, 0x10, 0x00, 0x00, 0x01, 0x02, 0x03, 0x20, 0x32, 0xEF, 0xF1,
          0x00, 0x71, 0x25, 0xEF, 0x62, 0x63>>

      expected_command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      expected_params = [
        seq_number: 0x01,
        status: :done,
        node_id: 0x09,
        command_classes: expected_command_classes,
        basic_device_class: :controller,
        generic_device_class: :static_controller,
        listening?: false,
        specific_device_class: :static_installer_tool
      ]

      {:ok, params} = NodeAddStatus.decode_params(report)

      for {param_name, value} <- expected_params do
        assert params[param_name] == value
      end
    end

    test "version 2 - S2 keys support" do
      report =
        <<0x01, 0x06, 0x00, 0x09, 0x10, 0x00, 0x00, 0x01, 0x02, 0x03, 0x20, 0x32, 0xEF, 0xF1,
          0x00, 0x71, 0x25, 0xEF, 0x62, 0x63, 0x07, 0x00>>

      expected_command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      expected_params = [
        seq_number: 0x01,
        status: :done,
        node_id: 0x09,
        command_classes: expected_command_classes,
        basic_device_class: :controller,
        generic_device_class: :static_controller,
        listening?: false,
        specific_device_class: :static_installer_tool,
        kex_fail_type: :none,
        granted_keys: [:s2_access_control, :s2_authenticated, :s2_unauthenticated]
      ]

      {:ok, params} = NodeAddStatus.decode_params(report)

      for {param_name, value} <- expected_params do
        assert params[param_name] == value
      end
    end

    test "version 3 - adds input DSK" do
      report =
        <<0x01, 0x06, 0x00, 0x09, 0x10, 0x00, 0x00, 0x01, 0x02, 0x03, 0x20, 0x32, 0xEF, 0xF1,
          0x00, 0x71, 0x25, 0xEF, 0x62, 0x63, 0x07, 0x00, 0x10, 0xC4, 0x6D, 0x49, 0x83, 0x26,
          0xC4, 0x77, 0xE3, 0x3E, 0x65, 0x83, 0xAF, 0xF, 0xA5, 0xE, 0x27>>

      expected_command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      {:ok, expected_dsk} = DSK.parse("50285-18819-09924-30691-15973-33711-04005-03623")

      expected_params = [
        seq_number: 0x01,
        status: :done,
        node_id: 0x09,
        command_classes: expected_command_classes,
        basic_device_class: :controller,
        generic_device_class: :static_controller,
        listening?: false,
        specific_device_class: :static_installer_tool,
        kex_fail_type: :none,
        granted_keys: [:s2_access_control, :s2_authenticated, :s2_unauthenticated],
        input_dsk: expected_dsk
      ]

      {:ok, params} = NodeAddStatus.decode_params(report)

      for {param_name, value} <- expected_params do
        assert params[param_name] == value
      end
    end

    test "z/ip gateway off-by-one workaround" do
      report =
        <<0x25, 0x7, 0x0, 0x7, 0x1A, 0x53, 0x9C, 0x4, 0x7, 0x1, 0x5E, 0x98, 0x9F, 0x6C, 0x55,
          0x86, 0x73, 0x85, 0x8E, 0x59, 0x72, 0x5A, 0x87, 0x80, 0x84, 0x71, 0x30, 0x31, 0x70>>

      expected_command_classes = [
        non_secure_supported: [
          :zwaveplus_info,
          :security,
          :security_2,
          :supervision,
          :transport_service,
          :version,
          :powerlevel,
          :association,
          :multi_channel_association,
          :association_group_info,
          :manufacturer_specific,
          :device_reset_locally,
          :indicator,
          :battery,
          :wake_up,
          :alarm,
          :sensor_binary,
          :sensor_multilevel,
          :configuration
        ],
        non_secure_controlled: [],
        secure_supported: [],
        secure_controlled: []
      ]

      expected_params = [
        status: :failed,
        node_id: 7,
        seq_number: 37,
        listening?: false,
        basic_device_class: :routing_end_node,
        generic_device_class: :sensor_notification,
        specific_device_class: :notification_sensor,
        command_classes: expected_command_classes
      ]

      {:ok, params} = NodeAddStatus.decode_params(report)

      for {param_name, value} <- expected_params do
        assert params[param_name] == value
      end
    end
  end

  test "handle whatever random weirdness z/ip gateway throws at us" do
    binary =
      <<0x34, 0x2, 0xA, 0x9, 0x0, 0x8, 0xC, 0xD3, 0x9C, 0x4, 0x10, 0x0, 0x5E, 0x9F, 0x98, 0x6C,
        0x55, 0x25, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0>>

    assert {:ok, command} = Grizzly.ZWave.from_binary(binary)
    assert :node_add_status == command.name
    assert 8 == command.params[:node_id]

    assert command.params[:command_classes][:non_secure_supported] == [
             :zwaveplus_info,
             :security_2,
             :security,
             :supervision,
             :transport_service,
             :switch_binary
           ]
  end
end
