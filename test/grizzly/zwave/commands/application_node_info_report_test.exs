defmodule Grizzly.ZWave.Commands.ApplicationNodeInfoReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Commands

  test "creates the command and validates params" do
    command_classes = [non_secure_supported: [:association_group_info]]

    assert {:ok, command} =
             Commands.create(:application_node_info_report, command_classes: command_classes)

    assert command.command_byte == 0x0D
  end

  test "encodes params correctly" do
    command_classes = [non_secure_supported: [:association_group_info]]

    {:ok, command} =
      Commands.create(:application_node_info_report, command_classes: command_classes)

    expected_binary = <<0x5F, 0xD, 0x59>>

    assert expected_binary == ZWave.to_binary(command)
  end

  test "decodes params correctly" do
    command_classes = [
      non_secure_supported: [:association_group_info],
      non_secure_controlled: [],
      secure_supported: [],
      secure_controlled: []
    ]

    {:ok, expected_command} =
      Commands.create(:application_node_info_report, command_classes: command_classes)

    binary = <<0x5F, 0xD, 0x59>>

    assert {:ok, expected_command} == ZWave.from_binary(binary)
  end
end
