defmodule Grizzly.ZWave.CommandClasses.NetworkManagementInclusionTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.DSK
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  describe "parsing node add status" do
    test "when status is done" do
      assert :done == NetworkManagementInclusion.parse_node_add_status(0x06)
    end

    test "when status is failed" do
      assert :failed == NetworkManagementInclusion.parse_node_add_status(0x07)
    end

    test "when status is security failed" do
      assert :security_failed == NetworkManagementInclusion.parse_node_add_status(0x09)
    end
  end

  describe "encoding node add status" do
    test "when status is done" do
      assert 0x06 == NetworkManagementInclusion.node_add_status_to_byte(:done)
    end

    test "when status is failed" do
      assert 0x07 == NetworkManagementInclusion.node_add_status_to_byte(:failed)
    end

    test "when status is security failed" do
      assert 0x09 == NetworkManagementInclusion.node_add_status_to_byte(:security_failed)
    end
  end

  describe "parsing node information" do
    test "version 1 - only a list of command classes" do
      node_info_bin =
        <<0x10, 0x00, 0x00, 0x01, 0x02, 0x03, 0x20, 0x32, 0xEF, 0xF1, 0x00, 0x71, 0x25, 0xEF,
          0x62, 0x63>>

      expected_command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      assert NetworkManagementInclusion.parse_node_info(node_info_bin) == %{
               command_classes: expected_command_classes,
               basic_device_class: :controller,
               generic_device_class: :static_controller,
               listening?: false,
               specific_device_class: :static_installer_tool
             }
    end

    test "version 2 - adds S2 key values" do
      node_info_bin =
        <<0x10, 0x00, 0x00, 0x01, 0x02, 0x03, 0x20, 0x32, 0xEF, 0xF1, 0x00, 0x71, 0x25, 0xEF,
          0x62, 0x63, 0x07, 0x00>>

      expected_command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      assert NetworkManagementInclusion.parse_node_info(node_info_bin) == %{
               command_classes: expected_command_classes,
               basic_device_class: :controller,
               generic_device_class: :static_controller,
               listening?: false,
               specific_device_class: :static_installer_tool,
               kex_fail_type: :none,
               keys_granted: [:s2_access_control, :s2_authenticated, :s2_unauthenticated]
             }
    end

    test "version 3 - adds input DSK field - when DSK is empty" do
      node_info_bin =
        <<0x10, 0x00, 0x00, 0x01, 0x02, 0x03, 0x20, 0x32, 0xEF, 0xF1, 0x00, 0x71, 0x25, 0xEF,
          0x62, 0x63, 0x07, 0x00, 0x00>>

      expected_command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      assert NetworkManagementInclusion.parse_node_info(node_info_bin) == %{
               command_classes: expected_command_classes,
               basic_device_class: :controller,
               generic_device_class: :static_controller,
               listening?: false,
               specific_device_class: :static_installer_tool,
               kex_fail_type: :none,
               keys_granted: [:s2_access_control, :s2_authenticated, :s2_unauthenticated]
             }
    end

    test "version 3 - adds input DSK field - when DSK is provided" do
      node_info_bin =
        <<0x10, 0x00, 0x00, 0x01, 0x02, 0x03, 0x20, 0x32, 0xEF, 0xF1, 0x00, 0x71, 0x25, 0xEF,
          0x62, 0x63, 0x07, 0x00, 0x10, 0xC4, 0x6D, 0x49, 0x83, 0x26, 0xC4, 0x77, 0xE3, 0x3E,
          0x65, 0x83, 0xAF, 0xF, 0xA5, 0xE, 0x27>>

      expected_command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      {:ok, expected_dsk} = DSK.parse("50285-18819-09924-30691-15973-33711-04005-03623")

      assert NetworkManagementInclusion.parse_node_info(node_info_bin) == %{
               command_classes: expected_command_classes,
               basic_device_class: :controller,
               generic_device_class: :static_controller,
               listening?: false,
               specific_device_class: :static_installer_tool,
               kex_fail_type: :none,
               keys_granted: [:s2_access_control, :s2_authenticated, :s2_unauthenticated],
               input_dsk: expected_dsk
             }
    end
  end
end
