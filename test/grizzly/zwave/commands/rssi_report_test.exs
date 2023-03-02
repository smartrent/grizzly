defmodule Grizzly.ZWave.Commands.RssiReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.RssiReport

  test "creates the command and validates params" do
    params = [channels: [:rssi_max_power_saturated, -94, :rssi_not_available]]
    {:ok, _command} = RssiReport.new(params)
  end

  test "encodes params correctly" do
    params = [channels: [:rssi_max_power_saturated, -94, :rssi_not_available]]
    {:ok, command} = RssiReport.new(params)
    expected_binary = <<0x7E, 0xA2, 0x7F>>
    assert expected_binary == RssiReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x7E, 0xA2, 0x7F>>
    {:ok, params} = RssiReport.decode_params(params_binary)
    assert [:rssi_max_power_saturated, -94, :rssi_not_available] == Keyword.get(params, :channels)
  end

  test "ignore non-standard channel" do
    params_binary = <<0x7E, 0xA2, 0x9E>>
    {:ok, params} = RssiReport.decode_params(params_binary)
    assert [:rssi_max_power_saturated, -94, -98] == Keyword.get(params, :channels)
  end

  test "encode version 4 - long range channels" do
    {:ok, cmd} =
      RssiReport.new(
        channels: [
          :rssi_max_power_saturated,
          -94,
          :rssi_not_available
        ],
        long_range_primary_channel: -94,
        long_range_secondary_channel: :rssi_not_available
      )

    assert RssiReport.encode_params(cmd) == <<0x7E, 0xA2, 0x7F, 0xA2, 0x7F>>
  end

  test "parses version 4 - long range channels" do
    expected_params = [
      channels: [
        :rssi_max_power_saturated,
        -94,
        :rssi_not_available
      ],
      long_range_primary_channel: -94,
      long_range_secondary_channel: :rssi_not_available
    ]

    binary = <<0x7E, 0xA2, 0x7F, 0xA2, 0x7F>>
    {:ok, params} = RssiReport.decode_params(binary)

    for {param, value} <- expected_params do
      assert params[param] == value
    end
  end

  test "handles z/ip gateway erroneously sending an illegal value for LR secondary" do
    expected_params = [
      channels: [-99, -102, -102],
      long_range_primary_channel: :rssi_not_available,
      long_range_secondary_channel: :rssi_not_available
    ]

    binary = <<0x9D, 0x9A, 0x9A, 0x7F, 0x00>>
    {:ok, params} = RssiReport.decode_params(binary)

    assert expected_params == params
  end
end
