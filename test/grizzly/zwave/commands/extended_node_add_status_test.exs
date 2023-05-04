defmodule Grizzly.ZWave.Commands.ExtendedNodeAddStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ExtendedNodeAddStatus

  test "ensure command byte is right" do
    {:ok, command} = ExtendedNodeAddStatus.new()

    assert command.command_byte == 0x16
  end

  test "ensure name is right" do
    {:ok, command} = ExtendedNodeAddStatus.new()

    assert command.name == :extended_node_add_status
  end

  describe "decode params" do
    test "version 4" do
      report =
        <<0x01, 0x06, 0x01, 0x2C, 0x10, 0x00, 0x00, 0x01, 0x02, 0x03, 0x20, 0x32, 0xEF, 0xF1,
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
        node_id: 0x012C,
        command_classes: expected_command_classes,
        basic_device_class: :controller,
        generic_device_class: :static_controller,
        listening?: false,
        specific_device_class: :static_installer_tool,
        kex_fail_type: :none,
        keys_granted: [:s2_access_control, :s2_authenticated, :s2_unauthenticated]
      ]

      {:ok, params} = ExtendedNodeAddStatus.decode_params(report)

      for {param_name, value} <- expected_params do
        assert params[param_name] == value
      end
    end
  end
end
