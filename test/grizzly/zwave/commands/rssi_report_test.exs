defmodule Grizzly.ZWave.Commands.RssiReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.RssiReport

  test "creates the command and validates params" do
    params = [channels: [:rssi_max_power_saturated, -94, :rssi_not_available]]
    {:ok, _command} = Commands.create(:rssi_report, params)
  end

  test "encodes params correctly" do
    params = [channels: [:rssi_max_power_saturated, -94, :rssi_not_available]]
    {:ok, command} = Commands.create(:rssi_report, params)
    expected_binary = <<0x7E, 0xA2, 0x7F>>
    assert expected_binary == RssiReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<0x7E, 0xA2, 0x7F>>
    {:ok, params} = RssiReport.decode_params(nil, params_binary)
    assert [:rssi_max_power_saturated, -94, :rssi_not_available] == Keyword.get(params, :channels)
  end

  test "ignore non-standard channel" do
    params_binary = <<0x7E, 0xA2, 0x9E>>
    {:ok, params} = RssiReport.decode_params(nil, params_binary)
    assert [:rssi_max_power_saturated, -94, -98] == Keyword.get(params, :channels)
  end

  test "encode version 4 - long range channels" do
    {:ok, cmd} =
      Commands.create(
        :rssi_report,
        channels: [
          :rssi_max_power_saturated,
          -94,
          :rssi_not_available
        ],
        long_range_primary_channel: -94,
        long_range_secondary_channel: :rssi_not_available
      )

    assert RssiReport.encode_params(nil, cmd) == <<0x7E, 0xA2, 0x7F, 0xA2, 0x7F>>
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
    {:ok, params} = RssiReport.decode_params(nil, binary)
    assert expected_params == params

    expected_params = [
      channels: [
        :rssi_max_power_saturated,
        -94,
        :rssi_not_available
      ],
      long_range_primary_channel: :rssi_not_available,
      long_range_secondary_channel: :rssi_not_available
    ]

    binary = <<0x7E, 0xA2, 0x7F, 0x7F, 0x00>>
    {:ok, params} = RssiReport.decode_params(nil, binary)
    assert expected_params == params

    expected_params = [
      channels: [
        :rssi_max_power_saturated,
        -94,
        :rssi_not_available
      ],
      long_range_primary_channel: :rssi_not_available,
      long_range_secondary_channel: -94
    ]

    binary = <<0x7E, 0xA2, 0x7F, 0x7F, 0xA2>>
    {:ok, params} = RssiReport.decode_params(nil, binary)
    assert expected_params == params
  end

  test "handles z/ip gateway erroneously sending an illegal value for LR secondary" do
    expected_params = [
      channels: [-99, -102, -102],
      long_range_primary_channel: :rssi_not_available,
      long_range_secondary_channel: :rssi_not_available
    ]

    binary = <<0x9D, 0x9A, 0x9A, 0x7F, 0x00>>
    {:ok, params} = RssiReport.decode_params(nil, binary)

    assert expected_params == params
  end

  test "decodes out-of-spec (but technically valid) values" do
    expected_params = [
      channels: [-98, -25, -25],
      long_range_primary_channel: -10,
      long_range_secondary_channel: :rssi_max_power_saturated
    ]

    # Received this from Z/IP Gateway sending this while I was jamming channels
    # 1 and 2 with a dev kit
    binary = <<0x9E, 0xE7, 0xE7, 0xF6, 0x7E>>
    {:ok, params} = RssiReport.decode_params(nil, binary)

    assert expected_params == params
  end

  test "encodes out-of-spec (but technically valid) values" do
    {:ok, cmd} =
      Commands.create(
        :rssi_report,
        channels: [-98, -25, -25],
        long_range_primary_channel: -10,
        long_range_secondary_channel: :rssi_max_power_saturated
      )

    # Received this from Z/IP Gateway sending this while I was jamming channels
    # 1 and 2 with a dev kit
    expected_binary = <<0x9E, 0xE7, 0xE7, 0xF6, 0x7E>>

    assert expected_binary == RssiReport.encode_params(nil, cmd)

    {:ok, cmd} =
      Commands.create(
        :rssi_report,
        channels: [100, -106, 20],
        long_range_primary_channel: 50,
        long_range_secondary_channel: :rssi_max_power_saturated
      )

    # Received this from Z/IP Gateway sending this while I was jamming channels
    # 1 and 2 with a dev kit
    expected_binary = <<0x64, 0x96, 0x14, 0x32, 0x7E>>

    assert expected_binary == RssiReport.encode_params(nil, cmd)
  end
end
