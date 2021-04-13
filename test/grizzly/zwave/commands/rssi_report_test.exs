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
    assert [:rssi_max_power_saturated, -94] == Keyword.get(params, :channels)
  end
end
