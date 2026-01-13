defmodule Grizzly.ZWave.Commands.MultiChannelCapabilityReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelCapabilityReport

  test "creates the command and validates params" do
    params = [
      end_point: 1,
      dynamic?: false,
      generic_device_class: :switch_binary,
      specific_device_class: :power_strip,
      command_classes: [:basic, :switch_binary]
    ]

    {:ok, _command} = Commands.create(:multi_channel_capability_report, params)
  end

  test "encodes params correctly" do
    params = [
      end_point: 1,
      dynamic?: false,
      generic_device_class: :switch_binary,
      specific_device_class: :power_strip,
      command_classes: [:basic, :switch_binary]
    ]

    {:ok, command} = Commands.create(:multi_channel_capability_report, params)
    expected_binary = <<0x00::1, 0x01::7, 0x10, 0x04, 0x20, 0x25>>
    assert expected_binary == MultiChannelCapabilityReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<0x00::1, 0x01::7, 0x10, 0x04, 0x20, 0x25>>
    {:ok, params} = MultiChannelCapabilityReport.decode_params(nil, params_binary)
    assert Keyword.get(params, :end_point) == 1
    assert Keyword.get(params, :dynamic?) == false
    assert Keyword.get(params, :generic_device_class) == :switch_binary
    assert Keyword.get(params, :specific_device_class) == :power_strip
    assert Keyword.get(params, :command_classes) == [:basic, :switch_binary]
  end
end
