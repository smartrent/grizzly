defmodule Grizzly.ZWave.CommandClassesTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.CommandClasses

  describe "Tagged command class lists" do
    test "Command classes to binary" do
      command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      expected_binary = <<0x20, 0x32, 0xEF, 0xF1, 0x00, 0x71, 0x25, 0xEF, 0x62, 0x63>>
      assert expected_binary == CommandClasses.command_class_list_to_binary(command_classes)
    end

    test "Command classes from binary" do
      expected_command_classes = [
        non_secure_supported: [:basic, :meter],
        non_secure_controlled: [],
        secure_supported: [:alarm, :switch_binary],
        secure_controlled: [:door_lock, :user_code]
      ]

      binary = <<0x20, 0x32, 0xEF, 0xF1, 0x00, 0x71, 0x25, 0xEF, 0x62, 0x63>>
      assert expected_command_classes == CommandClasses.command_class_list_from_binary(binary)
    end
  end
end
