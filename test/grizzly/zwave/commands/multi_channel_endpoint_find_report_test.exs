defmodule Grizzly.ZWave.Commands.MultiChannelEndpointFindReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MultiChannelEndpointFindReport

  test "creates the command and validates params" do
    params = [
      reports_to_follow: 0,
      generic_device_class: :switch_binary,
      specific_device_class: :power_strip,
      end_points: [2, 3]
    ]

    {:ok, _command} = MultiChannelEndpointFindReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      reports_to_follow: 0,
      generic_device_class: :switch_binary,
      specific_device_class: :power_strip,
      end_points: [2, 3]
    ]

    {:ok, command} = MultiChannelEndpointFindReport.new(params)
    expected_binary = <<0x00, 0x10, 0x04, 0x02, 0x03>>
    assert expected_binary == MultiChannelEndpointFindReport.encode_params(command)

    params = [
      reports_to_follow: 0,
      generic_device_class: :all,
      specific_device_class: :all,
      end_points: [2, 3]
    ]

    {:ok, command} = MultiChannelEndpointFindReport.new(params)
    expected_binary = <<0x00, 0xFF, 0xFF, 0x02, 0x03>>
    assert expected_binary == MultiChannelEndpointFindReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x00, 0x10, 0x04, 0x02, 0x03>>
    {:ok, params} = MultiChannelEndpointFindReport.decode_params(params_binary)
    assert Keyword.get(params, :reports_to_follow) == 0
    assert Keyword.get(params, :generic_device_class) == :switch_binary
    assert Keyword.get(params, :specific_device_class) == :power_strip
    assert Enum.sort(Keyword.get(params, :end_points)) == [2, 3]

    params_binary = <<0x00, 0xFF, 0xFF, 0x02, 0x03>>
    {:ok, params} = MultiChannelEndpointFindReport.decode_params(params_binary)
    assert Keyword.get(params, :reports_to_follow) == 0
    assert Keyword.get(params, :generic_device_class) == :all
    assert Keyword.get(params, :specific_device_class) == :all
    assert Enum.sort(Keyword.get(params, :end_points)) == [2, 3]
  end
end
