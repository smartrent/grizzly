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
        basic_device_class: 1,
        generic_device_class: 2,
        listening?: false,
        specific_device_class: 3
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
        basic_device_class: 1,
        generic_device_class: 2,
        listening?: false,
        specific_device_class: 3,
        kex_fail_type: :none,
        keys_granted: [:s2_access_control, :s2_authenticated, :s2_unauthenticated]
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
        basic_device_class: 1,
        generic_device_class: 2,
        listening?: false,
        specific_device_class: 3,
        kex_fail_type: :none,
        keys_granted: [:s2_access_control, :s2_authenticated, :s2_unauthenticated],
        input_dsk: expected_dsk
      ]

      {:ok, params} = NodeAddStatus.decode_params(report)

      for {param_name, value} <- expected_params do
        assert params[param_name] == value
      end
    end
  end
end
